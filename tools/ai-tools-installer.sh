#!/usr/bin/env bash
# ============================================================
# AI 工具一键安装脚本
# 支持 Claude Code / Codex CLI / OpenCode CLI
# 自动检测系统，拒绝不支持的环境，可视化进度
# ============================================================
set -euo pipefail

# --------------- 颜色 ---------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0; TOTAL=0

# --------------- Banner ---------------
banner() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║        🤖 AI 工具一键安装脚本 v2.0           ║"
  echo "║   Claude Code · Codex CLI · OpenCode CLI     ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# --------------- 进度条 ---------------
spinner() { local pid=$1; local s=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'); local i=0; while kill -0 "$pid" 2>/dev/null; do printf "\r  ${CYAN}%s${NC} 处理中..." "${s[$((i%10))]}"; i=$((i+1)); sleep 0.1; done; printf "\r"; wait "$pid"; return $?; }

progress_bar() {
  local current=$1 total=$2 label=${3:-}; local width=30
  local pct=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))
  local bar=$(printf "%-${filled}s" '' | tr ' ' '█')$(printf "%-${empty}s" '' | tr ' ' '░')
  if [ "$DRY_RUN" = true ]; then label="[模拟] $label"; fi
  printf "\r  [%s%s] %3d%%  %s" "$bar" "" "$pct" "$label"
}

step_ok()   { ((PASS++)); ((TOTAL++)); echo -e " ${GREEN}✅ $1${NC}"; }
step_fail() { ((FAIL++)); ((TOTAL++)); echo -e " ${RED}❌ $1${NC}"; }
step_warn() { ((WARN++)); ((TOTAL++)); echo -e " ${YELLOW}⚠️  $1${NC}"; }

# --------------- 系统检测 ---------------
detect_system() {
  echo -e "\n${BOLD}🔍 第一步：检测当前系统环境${NC}\n"
  
  OS_TYPE=""; OS_VERSION=""; OS_ID=""; ARCH=""; PACKAGE_MANAGER=""

  # 架构检测
  ARCH=$(uname -m)
  if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  不支持: CPU 架构 $ARCH${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "这些 AI 工具目前只支持 x86_64 (Intel/AMD) 和 ARM64 (M1/M2/M3) 架构。"
    exit 1
  fi

  KERNEL=$(uname -s)

  # ---- Windows 检测（拒绝）----
  case "$KERNEL" in
    MINGW*|MSYS*|CYGWIN*)
      echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${RED}  不支持: Windows 原生环境${NC}"
      echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "这些工具需要在 Linux/macOS 环境下运行。"
      echo "Windows 用户请使用 WSL2（Windows Subsystem for Linux）："
      echo ""
      echo "  1. 以管理员身份打开 PowerShell"
      echo "  2. 运行: wsl --install"
      echo "  3. 重启电脑"
      echo "  4. 在 WSL Ubuntu 终端中重新运行本脚本："
      echo "     curl -fsSL https://4si.cc/tools/ai-tools-installer.sh | bash"
      echo ""
      exit 1
      ;;
  esac

  # ---- macOS 检测 ----
  if [ "$KERNEL" = "Darwin" ]; then
    OS_TYPE="macOS"
    OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    PACKAGE_MANAGER="brew"
    step_ok "系统: macOS $OS_VERSION ($ARCH)"
    
    MAJOR_VER=$(echo "$OS_VERSION" | cut -d. -f1)
    if [ "$MAJOR_VER" -lt 12 ] 2>/dev/null; then
      step_warn "macOS 版本较旧 (< 12)，部分工具可能无法正常运行，建议升级到 macOS 13+"
    fi

    if ! command -v brew &>/dev/null; then
      step_warn "未检测到 Homebrew，安装过程可能需要手动处理依赖"
    else
      step_ok "包管理器: Homebrew 已就绪"
    fi
    return 0
  fi

  # ---- Linux 检测 ----
  if [ "$KERNEL" = "Linux" ]; then
    # 检测 WSL
    if grep -qiE "(Microsoft|WSL)" /proc/version 2>/dev/null; then
      WSL_VERSION=$(grep -oP 'WSL\K[0-9]' /proc/version 2>/dev/null || echo "?")
      OS_TYPE="WSL$WSL_VERSION"
      if [ "$WSL_VERSION" = "1" ]; then
        step_warn "检测到 WSL1，部分功能受限，建议升级到 WSL2（wsl --set-version <distro> 2）"
      else
        step_ok "系统: WSL2 ($ARCH)"
      fi
    fi

    # 读取发行版信息
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID="$ID"
      OS_VERSION="${VERSION_ID:-unknown}"
      if [ "$OS_TYPE" = "" ]; then OS_TYPE="$ID"; fi
      step_ok "发行版: $NAME $VERSION_ID"
    else
      step_fail "无法识别 Linux 发行版（缺少 /etc/os-release）"
    fi

    # ---- 具体发行版处理 ----
    case "$OS_ID" in
      ubuntu)
        PACKAGE_MANAGER="apt"
        MAJOR_VER=$(echo "$OS_VERSION" | cut -d. -f1)
        if [ "$MAJOR_VER" -lt 20 ] 2>/dev/null; then
          step_warn "Ubuntu $OS_VERSION < 20.04，建议升级到 20.04+ 以获得最佳体验"
        else
          step_ok "Ubuntu $OS_VERSION 满足最低版本要求"
        fi
        ;;
      debian)
        PACKAGE_MANAGER="apt"
        MAJOR_VER=$(echo "$OS_VERSION" | cut -d. -f1)
        if [ "$MAJOR_VER" -lt 11 ] 2>/dev/null; then
          step_warn "Debian $OS_VERSION < 11，建议升级到 Debian 11+"
        else
          step_ok "Debian $OS_VERSION 满足要求"
        fi
        ;;
      fedora|rhel|centos|rocky|almalinux)
        PACKAGE_MANAGER="dnf"
        step_ok "发行版: $ID $OS_VERSION — 使用 dnf 包管理器"
        ;;
      arch|manjaro|endeavouros)
        PACKAGE_MANAGER="pacman"
        step_ok "发行版: $ID — 使用 pacman 包管理器"
        ;;
      *)
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  不支持: Linux 发行版 \"$ID\"${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "当前支持的发行版:"
        echo "  ✅ Ubuntu 20.04+"
        echo "  ✅ Debian 11+"
        echo "  ✅ Fedora / RHEL / CentOS / Rocky / AlmaLinux"
        echo "  ✅ Arch / Manjaro / EndeavourOS"
        echo "  ✅ WSL2 (Ubuntu)"
        echo "  ✅ macOS 12+"
        echo ""
        echo "你的发行版 \"$ID\" 尚未测试，可以尝试手动安装："
        echo "  - Claude Code: https://code.claude.com/docs/en/cli-reference"
        echo "  - Codex CLI:    https://github.com/openai/codex"
        echo "  - OpenCode CLI: https://opencode.ai"
        exit 1
        ;;
    esac
    
    return 0
  fi

  echo -e "${RED}不支持的操作系统: $KERNEL${NC}"
  exit 1
}

# --------------- 依赖安装 ---------------
install_nodejs() {
  local ver; ver=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1 || echo "0")
  if [ "$ver" -ge 18 ] 2>/dev/null; then
    step_ok "Node.js v$(node --version) 已安装且版本满足要求"
    return 0
  fi

  step_warn "Node.js 未安装或版本过低（需要 ≥ 18）"
  
  if [ "$DRY_RUN" = true ]; then
    step_ok "[模拟] 将安装 Node.js 20 LTS"
    return 0
  fi

  echo -e "  ${CYAN}正在安装 Node.js 20 LTS...${NC}"
  case "$OS_TYPE" in
    macOS*)
      if command -v brew &>/dev/null; then
        brew install node@20 2>/dev/null && step_ok "Node.js 安装成功" || step_fail "Node.js 安装失败"
      else
        step_fail "需要 Homebrew，请先安装: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      fi
      ;;
    WSL*|ubuntu|debian)
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null
      sudo apt-get install -y nodejs 2>/dev/null && step_ok "Node.js 安装成功" || step_fail "Node.js 安装失败"
      ;;
    fedora|rhel|centos|rocky|almalinux)
      curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - 2>/dev/null
      sudo dnf install -y nodejs 2>/dev/null && step_ok "Node.js 安装成功" || step_fail "Node.js 安装失败"
      ;;
    arch|manjaro|endeavouros)
      sudo pacman -S --noconfirm nodejs npm 2>/dev/null && step_ok "Node.js 安装成功" || step_fail "Node.js 安装失败"
      ;;
  esac
}

install_python3() {
  if command -v python3 &>/dev/null; then
    local ver; ver=$(python3 --version 2>/dev/null | awk '{print $2}' | cut -d. -f1)
    if [ "$ver" -ge 3 ] 2>/dev/null; then
      step_ok "Python3 $(python3 --version | awk '{print $2}') 已就绪"
      return 0
    fi
  fi
  
  step_warn "Python3 未安装"
  if [ "$DRY_RUN" = true ]; then
    step_ok "[模拟] 将安装 Python3"
    return 0
  fi

  case "$OS_TYPE" in
    macOS*)   brew install python3 2>/dev/null && step_ok "Python3 安装成功" || step_fail "Python3 安装失败" ;;
    WSL*|ubuntu|debian) sudo apt-get install -y python3 python3-pip 2>/dev/null && step_ok "Python3 安装成功" || step_fail "Python3 安装失败" ;;
    fedora|rhel|centos|rocky|almalinux) sudo dnf install -y python3 python3-pip 2>/dev/null && step_ok "Python3 安装成功" || step_fail "Python3 安装失败" ;;
    arch|manjaro|endeavouros) sudo pacman -S --noconfirm python python-pip 2>/dev/null && step_ok "Python3 安装成功" || step_fail "Python3 安装失败" ;;
  esac
}

check_git() {
  if command -v git &>/dev/null; then
    step_ok "Git $(git --version | awk '{print $NF}') 已就绪"
  else
    step_warn "Git 未安装"
    if [ "$DRY_RUN" = true ]; then
      step_ok "[模拟] 将安装 Git"
      return 0
    fi
    case "$PACKAGE_MANAGER" in
      brew) brew install git 2>/dev/null && step_ok "Git 安装成功" || step_fail "Git 安装失败" ;;
      apt)  sudo apt-get install -y git 2>/dev/null && step_ok "Git 安装成功" || step_fail "Git 安装失败" ;;
      dnf)  sudo dnf install -y git 2>/dev/null && step_ok "Git 安装成功" || step_fail "Git 安装失败" ;;
      pacman) sudo pacman -S --noconfirm git 2>/dev/null && step_ok "Git 安装成功" || step_fail "Git 安装失败" ;;
    esac
  fi
}

# --------------- 工具安装 ---------------
install_claude_code() {
  echo -e "\n  ${BOLD}📦 安装 Claude Code${NC}"
  
  if command -v claude &>/dev/null && ! echo "$(claude --version 2>&1)" | grep -qi "error"; then
    step_ok "Claude Code 已安装: $(claude --version 2>&1 | head -1)"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    step_ok "[模拟] npm install -g @anthropic-ai/claude-code"
    return 0
  fi

  sudo npm install -g @anthropic-ai/claude-code 2>/dev/null
  
  if command -v claude &>/dev/null; then
    step_ok "Claude Code 安装成功: $(claude --version 2>&1 | head -1)"
  else
    step_fail "Claude Code 安装失败"
    return 1
  fi
}

install_codex() {
  echo -e "\n  ${BOLD}📦 安装 Codex CLI${NC}"
  
  if command -v codex &>/dev/null; then
    step_ok "Codex CLI 已安装"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    step_ok "[模拟] npm install -g @openai/codex"
    return 0
  fi

  sudo npm install -g @openai/codex 2>/dev/null
  
  if command -v codex &>/dev/null; then
    step_ok "Codex CLI 安装成功"
  else
    step_fail "Codex CLI 安装失败"
    return 1
  fi
}

install_opencode() {
  echo -e "\n  ${BOLD}📦 安装 OpenCode CLI${NC}"
  
  if command -v opencode &>/dev/null; then
    step_ok "OpenCode CLI 已安装"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    step_ok "[模拟] npm install -g @opencode-ai/cli"
    return 0
  fi

  sudo npm install -g @opencode-ai/cli 2>/dev/null
  
  if command -v opencode &>/dev/null; then
    step_ok "OpenCode CLI 安装成功"
  else
    step_fail "OpenCode CLI 安装失败（可能包名已变更，请参考 https://opencode.ai）"
    return 1
  fi
}

# --------------- 安装后验证 ---------------
verify_tools() {
  echo -e "\n${BOLD}🔬 安装后验证${NC}\n"
  
  for tool in "$@"; do
    case "$tool" in
      claude-code)
        if command -v claude &>/dev/null; then
          step_ok "Claude Code: $(claude --version 2>&1 | head -1)"
        else
          step_fail "Claude Code: 命令不可用"
        fi
        ;;
      codex)
        if command -v codex &>/dev/null; then
          step_ok "Codex CLI: 已安装"
        else
          step_fail "Codex CLI: 命令不可用"
        fi
        ;;
      opencode)
        if command -v opencode &>/dev/null; then
          step_ok "OpenCode CLI: 已安装"
        else
          step_fail "OpenCode CLI: 命令不可用"
        fi
        ;;
    esac
  done
}

# --------------- 交互选择 ---------------
select_tools() {
  echo -e "\n${BOLD}📋 请选择要安装的 AI 工具：${NC}\n"
  echo "  1) 🤖 Claude Code      — Anthropic 的 CLI 编程助手"
  echo "  2) 🚀 Codex CLI         — OpenAI 的命令行助手"
  echo "  3) 🔓 OpenCode CLI      — 开源、不挑模型的 CLI 助手"
  echo "  4) 🎯 全部安装           — 三件套一键全装"
  echo "  0) ❌ 退出"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}  ⚠️  模拟运行模式，不会真正修改系统${NC}\n"
  fi

  read -r -p "  输入数字选择 (1-4, 0): " choice
  
  case "$choice" in
    1) TOOLS=("claude-code") ;;
    2) TOOLS=("codex") ;;
    3) TOOLS=("opencode") ;;
    4) TOOLS=("claude-code" "codex" "opencode") ;;
    0) echo -e "\n  👋 已取消"; exit 0 ;;
    *) echo -e "\n  ${RED}无效选择，请重新运行${NC}"; exit 1 ;;
  esac
}

# --------------- 安装报告 ---------------
generate_report() {
  local elapsed=$1
  echo -e "\n${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║           📊 安装报告                          ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}\n"
  
  echo -e "  ${BOLD}系统信息${NC}"
  echo "    操作系统: $OS_TYPE $OS_VERSION"
  echo "    CPU 架构: $ARCH"
  echo "    包管理器: $PACKAGE_MANAGER"
  echo ""
  
  echo -e "  ${BOLD}安装结果${NC}"
  echo "    ✅ 成功: $PASS 项"
  echo "    ❌ 失败: $FAIL 项"
  echo "    ⚠️  警告: $WARN 项"
  echo "    ⏱️  耗时: ${elapsed}s"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}⚠️  这是模拟运行，系统未被修改。去掉 --dry-run 参数后执行真实安装。${NC}\n"
  fi

  if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}🎉 全部安装成功！${NC}\n"
    echo "  📖 下一步："
    echo "     - Claude Code 配置: https://4si.cc/03-claude-config.html"
    echo "     - Hermes Agent 安装: https://4si.cc/04-hermes-install.html"
    echo "     - 完整教程目录: https://4si.cc/"
    echo ""
  else
    echo -e "  ${RED}⚠️  有 $FAIL 项失败，请检查上面的错误信息。${NC}"
    echo "  🩺 故障排除: https://4si.cc/07-faq.html"
    echo ""
  fi
}

# --------------- Main ---------------
main() {
  DRY_RUN=false
  
  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true; shift ;;
      *) echo "未知参数: $1"; echo "用法: $0 [--dry-run]"; exit 1 ;;
    esac
  done

  banner
  
  # 1. 系统检测
  detect_system
  
  # 2. 交互选择
  select_tools
  
  # 3. 依赖检查与安装
  echo -e "\n${BOLD}📦 第二步：检查依赖${NC}\n"
  START_TIME=$(date +%s)
  
  install_nodejs
  install_python3
  check_git
  
  # 4. 安装工具
  echo -e "\n${BOLD}🔧 第三步：安装 AI 工具${NC}"
  for tool in "${TOOLS[@]}"; do
    case "$tool" in
      claude-code) install_claude_code ;;
      codex)       install_codex ;;
      opencode)    install_opencode ;;
    esac
  done
  
  # 5. 验证
  verify_tools "${TOOLS[@]}"
  
  ELAPSED=$(( $(date +%s) - START_TIME ))
  
  # 6. 报告
  generate_report "$ELAPSED"
}

main "$@"
