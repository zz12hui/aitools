/* === AI 工具入门系列 — Interactive Effects === */
(function(){
  'use strict';
  // Named constants (formerly magic numbers)
  var PARTICLE_COUNT = 40;
  var SLIDE_INTERVAL_MS = 4000;
  var REVEAL_THRESHOLD = 0.15;
  var TILT_MAX_DEG = 8;
  var COUNTER_DURATION_MS = 1500;
  var SCROLL_NAV_THRESHOLD = 30;

  // ===== PARTICLE BACKGROUND =====
  var particles = document.getElementById('particles');
  if(particles){
    for(var i=0; i<PARTICLE_COUNT; i++){
      var dot = document.createElement('div');
      dot.className = 'dot';
      var size = Math.random()*3+1;
      dot.style.width = size+'px';
      dot.style.height = size+'px';
      dot.style.left = Math.random()*100+'%';
      dot.style.animationDuration = (Math.random()*8+6)+'s';
      dot.style.animationDelay = (Math.random()*8)+'s';
      particles.appendChild(dot);
    }
  }

  // ===== HERO TITLE CHAR REVEAL =====
  var heroH1 = document.querySelector('.hero h1');
  if(heroH1){
    var text = heroH1.textContent;
    heroH1.textContent = '';
    var chars = Array.from(text);
    chars.forEach(function(ch, idx){
      var span = document.createElement('span');
      span.className = 'char-reveal';
      if(ch === ' ') span.classList.add('space');
      span.textContent = ch;
      span.style.animationDelay = (idx * 0.04) + 's';
      heroH1.appendChild(span);
    });
  }

  // ===== SLIDESHOW =====
  var slides = document.querySelectorAll('.slide');
  var dots = document.querySelectorAll('.slide-dots button');
  if(slides.length){
    var current = 0;
    var total = slides.length;
    function goTo(idx){
      slides.forEach(function(s,i){
        s.classList.remove('active','prev');
        if(i===idx) s.classList.add('active');
        else if(i===((idx-1+total)%total)) s.classList.add('prev');
      });
      dots.forEach(function(d,i){d.classList.toggle('active', i===idx);});
      current = idx;
    }
    dots.forEach(function(d,i){d.addEventListener('click',function(){goTo(i);});});
    // Auto rotate every 4s
    var slideInterval = setInterval(function(){goTo((current+1)%total);}, SLIDE_INTERVAL_MS);
    // Cleanup on page unload
    window.addEventListener('beforeunload',function(){clearInterval(slideInterval);});
    // Touch swipe
    var touchX = 0;
    var sw = document.querySelector('.slideshow');
    if(sw){
      sw.addEventListener('touchstart',function(e){
        if(e.touches.length) touchX=e.touches[0].clientX;
      });
      sw.addEventListener('touchend',function(e){
        if(!e.changedTouches.length) return;
        var dx = e.changedTouches[0].clientX - touchX;
        if(dx < -40) goTo((current+1)%total);
        if(dx > 40) goTo((current-1+total)%total);
      });
    }
  }

  // ===== SCROLL REVEAL =====
  var reveals = document.querySelectorAll('.reveal');
  var obsOptions = {threshold:REVEAL_THRESHOLD,rootMargin:'0px 0px -40px 0px'};
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries){
      entries.forEach(function(e){if(e.isIntersecting) e.target.classList.add('visible');});
    }, obsOptions);
    reveals.forEach(function(el){observer.observe(el);});
  } else {
    document.querySelectorAll('.reveal').forEach(function(el){el.classList.add('visible');});
  }

  // ===== CARD 3D TILT (desktop only) =====
  if(window.matchMedia('(hover:hover)').matches){
    document.querySelectorAll('.card').forEach(function(card){
      var cardRect, rafId;
      // Cache bounding rect on mouse enter
      card.addEventListener('mouseenter',function(){
        cardRect = card.getBoundingClientRect();
      });
      // Throttle mousemove with requestAnimationFrame
      card.addEventListener('mousemove',function(e){
        if(!cardRect) return;
        if(rafId) return;
        rafId = requestAnimationFrame(function(){
          rafId = null;
          var x = e.clientX - cardRect.left;
          var y = e.clientY - cardRect.top;
          var cx = cardRect.width/2, cy = cardRect.height/2;
          var rx = (y-cy)/cy*TILT_MAX_DEG;
          var ry = (x-cx)/cx*-TILT_MAX_DEG;
          card.style.transform = 'perspective(800px) rotateX('+rx+'deg) rotateY('+ry+'deg) scale(1.03)';
        });
      });
      card.addEventListener('mouseleave',function(){
        if(rafId){cancelAnimationFrame(rafId);rafId=null;}
        card.style.transform = 'perspective(800px) rotateX(0) rotateY(0) scale(1)';
      });
    });
  }

  // ===== CLICK RIPPLE =====
  document.querySelectorAll('.card,.path').forEach(function(el){
    el.addEventListener('click',function(e){
      var ripple = document.createElement('span');
      ripple.className = 'ripple';
      var rect = el.getBoundingClientRect();
      var size = Math.max(rect.width, rect.height);
      ripple.style.width = ripple.style.height = size+'px';
      ripple.style.left = (e.clientX-rect.left-size/2)+'px';
      ripple.style.top = (e.clientY-rect.top-size/2)+'px';
      el.appendChild(ripple);
      ripple.addEventListener('animationend',function(){ripple.remove();},{once:true});
    });
  });

  // ===== COUNTER ANIMATION (scroll-triggered with bounce) =====
  var heroStats = document.querySelector('.hero-stats');
  var countersAnimated = false;
  function animateCounters(){
    if(countersAnimated) return;
    countersAnimated = true;
    var counters = document.querySelectorAll('.stat strong');
    counters.forEach(function(c){
      var raw = c.textContent.replace(/,/g,'');
      var target = parseInt(raw);
      if(isNaN(target)) return;
      // Add animated class for bounce effect
      var statEl = c.closest('.stat');
      if(statEl) statEl.classList.add('animated');
      var startTime = performance.now();
      var duration = COUNTER_DURATION_MS;
      function tick(now){
        var elapsed = now - startTime;
        var progress = Math.min(elapsed / duration, 1);
        // Ease-out cubic for smoother count-up
        var eased = 1 - Math.pow(1 - progress, 3);
        var count = eased * target;
        if(progress >= 1){
          c.textContent = target.toLocaleString();
          // Remove bounce class after animation completes
          if(statEl) statEl.classList.remove('animated');
        } else {
          c.textContent = Math.floor(count).toLocaleString();
          requestAnimationFrame(tick);
        }
      }
      requestAnimationFrame(tick);
    });
  }
  if(heroStats){
    // Trigger counters when hero-stats is visible
    if('IntersectionObserver' in window){
      var counterObserver = new IntersectionObserver(function(entries){
        entries.forEach(function(e){
          if(e.isIntersecting) animateCounters();
        });
      }, {threshold: 0.5});
      counterObserver.observe(heroStats);
    } else {
      // Fallback: animate after a short delay
      setTimeout(animateCounters, 300);
    }
  }

  // ===== SMOOTH PARALLAX ON HERO =====
  var hero = document.querySelector('.hero');
  if(hero){
    window.addEventListener('scroll',function(){
      var scrollY = window.scrollY;
      if(scrollY < window.innerHeight){
        hero.style.transform = 'translateY('+(scrollY*0.15)+'px)';
        hero.style.opacity = Math.max(0.4, 1-scrollY/window.innerHeight);
      }
    },{passive:true});
  }

  // ===== TOP-NAV FROSTED GLASS ON SCROLL =====
  var topNav = document.querySelector('.top-nav');
  if(topNav){
    window.addEventListener('scroll',function(){
      if(window.scrollY > SCROLL_NAV_THRESHOLD){
        topNav.classList.add('nav-scrolled');
      } else {
        topNav.classList.remove('nav-scrolled');
      }
    },{passive:true});
  }

  // ===== INSTALLER PAGE: COPY COMMAND BUTTONS =====
  function doCopy(text, btn) {
    if (btn._timeout) { clearTimeout(btn._timeout); }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function() {
        btn.innerText = '✅ 已复制';
        btn.classList.add('copied');
        btn._timeout = setTimeout(function() { btn.innerText = '📋 复制'; btn.classList.remove('copied'); }, 2000);
      }).catch(function() { fallbackCopy(text, btn); });
    } else {
      fallbackCopy(text, btn);
    }
  }
  function fallbackCopy(text, btn) {
    if (btn._timeout) { clearTimeout(btn._timeout); }
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed'; ta.style.left = '-9999px';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); btn.innerText = '✅ 已复制'; btn.classList.add('copied'); }
    catch(e) { btn.innerText = '⚠️ 复制失败，请手动选择'; btn.style.background = '#f38ba8'; }
    document.body.removeChild(ta);
    btn._timeout = setTimeout(function() { btn.innerText = '📋 复制'; btn.classList.remove('copied'); btn.style.background = ''; }, 2000);
  }
  window.copyCmd = function() {
    var el = document.getElementById('install-cmd');
    var btn = document.getElementById('copy-btn-1');
    if (!el || !btn) return;
    doCopy(el.innerText, btn);
  };
  window.copyDryCmd = function() {
    var el = document.getElementById('dryrun-cmd');
    var btn = document.getElementById('copy-btn-2');
    if (!el || !btn) return;
    doCopy(el.innerText, btn);
  };

})();

  // ===== 3D TAG CLOUD =====
  (function(){
    var container = document.querySelector('.tag-cloud-container');
    var cloud = document.getElementById('tagCloud');
    if (!container || !cloud) return;

    // Tag data: [label, frequency, color, href]
    var tags = [
      ['AI', 19, 'blue', 'index-nav.html'],
      ['HermesAgent', 9, 'purple', 'index-nav.html'],
      ['ClaudeCode', 9, 'orange', 'index-nav.html'],
      ['教程', 8, 'white', 'index-nav.html'],
      ['安装', 4, 'green', 'index-nav.html'],
      ['进阶', 3, 'cyan', 'index-nav.html'],
      ['Skill', 3, 'purple', 'index-nav.html'],
      ['高阶', 2, 'yellow', 'index-nav.html'],
      ['配置', 2, 'orange', 'index-nav.html'],
      ['编程助手', 2, 'blue', 'index-nav.html'],
      ['开源', 2, 'green', 'index-nav.html'],
      ['入门', 2, 'pink', 'index-nav.html'],
      ['OpenCode', 2, 'cyan', 'index-nav.html'],
      ['Codex', 2, 'green', 'index-nav.html'],
      ['选型', 1, 'yellow', 'index-nav.html'],
      ['迁移', 1, 'pink', 'index-nav.html'],
      ['自定义', 1, 'purple', 'index-nav.html'],
      ['脚本', 1, 'orange', 'index-nav.html'],
      ['模板', 1, 'blue', 'index-nav.html'],
      ['故障排除', 1, 'pink', 'index-nav.html'],
      ['插件', 1, 'cyan', 'index-nav.html'],
      ['推荐', 1, 'yellow', 'index-nav.html'],
      ['对比', 1, 'white', 'index-nav.html'],
      ['安装脚本', 1, 'green', 'index-nav.html'],
      ['多平台', 1, 'blue', 'index-nav.html'],
      ['VSCode', 1, 'orange', 'index-nav.html'],
      ['Skills', 1, 'purple', 'index-nav.html'],
      ['OpenClaw', 1, 'pink', 'index-nav.html'],
      ['OpenAI', 1, 'green', 'index-nav.html'],
      ['MCP', 1, 'cyan', 'index-nav.html']
    ];

    var count = tags.length;
    var minFreq = 1, maxFreq = 19;
    var sizeMin = 0.8, sizeMax = 2.2;
    var weightMin = 400, weightMax = 800;
    var freqRange = maxFreq - minFreq;

    // Helper: map frequency to size/weight
    function freqToSize(f) {
      return sizeMin + (f - minFreq) / freqRange * (sizeMax - sizeMin);
    }
    function freqToWeight(f) {
      return Math.round(weightMin + (f - minFreq) / freqRange * (weightMax - weightMin));
    }

    // Fibonacci sphere: distribute tags on a unit sphere
    var phi = Math.PI * (3 - Math.sqrt(5)); // golden angle
    var positions = [];
    for (var i = 0; i < count; i++) {
      var y = 1 - (i / (count - 1)) * 2; // from 1 to -1
      var radiusAtY = Math.sqrt(1 - y * y);
      var theta = phi * i;
      positions.push({
        x: Math.cos(theta) * radiusAtY,
        y: y,
        z: Math.sin(theta) * radiusAtY
      });
    }

    // Create tag elements
    var tagEls = [];
    var sphereRadius = 160; // will be recalculated on resize
    tags.forEach(function(t, i) {
      var a = document.createElement('a');
      a.className = 'tag-item';
      a.href = t[3] || '#';
      a.textContent = t[0];
      a.setAttribute('data-color', t[2]);
      var size = freqToSize(t[1]);
      var weight = freqToWeight(t[1]);
      a.style.fontSize = size.toFixed(2) + 'em';
      a.style.fontWeight = weight;
      cloud.appendChild(a);
      tagEls.push({ el: a, pos: positions[i], freq: t[1] });
    });

    // Recalculate sphere radius based on container size
    function updateRadius() {
      var w = container.clientWidth;
      var h = container.clientHeight;
      sphereRadius = Math.min(w, h) * 0.38;
    }
    updateRadius();

    // Position all tags on the sphere
    function positionTags(rx, ry) {
      // rx, ry are rotation angles in radians
      var cosX = Math.cos(rx), sinX = Math.sin(rx);
      var cosY = Math.cos(ry), sinY = Math.sin(ry);
      for (var i = 0; i < tagEls.length; i++) {
        var p = tagEls[i].pos;
        // Rotate around X axis
        var y1 = p.y * cosX - p.z * sinX;
        var z1 = p.y * sinX + p.z * cosX;
        // Rotate around Y axis
        var x2 = p.x * cosY + z1 * sinY;
        var z2 = -p.x * sinY + z1 * cosY;
        // Apply sphere radius and position
        var tx = x2 * sphereRadius;
        var ty = y1 * sphereRadius;
        var tz = z2 * sphereRadius;
        tagEls[i].el.style.transform = 'translate3d(' + tx.toFixed(1) + 'px,' + ty.toFixed(1) + 'px,' + tz.toFixed(1) + 'px)';
        // Opacity based on depth (front = brighter)
        var depth = (z2 + 1) / 2; // 0 to 1
        var opacity = 0.3 + depth * 0.7;
        tagEls[i].el.style.opacity = opacity.toFixed(2);
      }
    }

    // Initial rotation: tilted axis
    var angleX = 0.3; // slight upward tilt
    var angleY = 0;
    positionTags(angleX, angleY);

    // Auto-rotation
    var autoSpeed = 0.004; // radians per frame (~0.24 rad/s at 60fps)
    var isHovering = false;
    var rafId = null;

    // Mouse parallax — tilt toward cursor
    var mouseX = 0, mouseY = 0;
    var targetTiltX = 0, targetTiltY = 0;
    var currentTiltX = 0, currentTiltY = 0;
    var parallaxStrength = 0.0003; // subtle ~10px displacement

    // Throttled mouse tracking
    var lastMouseTime = 0;
    container.addEventListener('mousemove', function(e) {
      var now = performance.now();
      if (now - lastMouseTime < 32) return; // ~30fps throttle
      lastMouseTime = now;
      var rect = container.getBoundingClientRect();
      mouseX = (e.clientX - rect.left) / rect.width - 0.5; // -0.5 to 0.5
      mouseY = (e.clientY - rect.top) / rect.height - 0.5;
    });

    function updateParallax() {
      targetTiltX = mouseY * parallaxStrength * sphereRadius;
      targetTiltY = mouseX * parallaxStrength * sphereRadius;
      currentTiltX += (targetTiltX - currentTiltX) * 0.08;
      currentTiltY += (targetTiltY - currentTiltY) * 0.08;
      cloud.style.transform = 'translate(' + currentTiltY.toFixed(1) + 'px,' + currentTiltX.toFixed(1) + 'px)';
    }

    function rotate() {
      if (!isHovering) {
        angleY += autoSpeed;
      }
      positionTags(angleX, angleY);
      updateParallax();
      rafId = requestAnimationFrame(rotate);
    }
    rafId = requestAnimationFrame(rotate);

    // Hover: pause rotation + enlarge tag
    tagEls.forEach(function(te) {
      te.el.addEventListener('mouseenter', function() {
        isHovering = true;
        te.el.style.transform = te.el.style.transform.replace(/translate3d\([^)]+\)/, function(m) {
          // Scale up by 20%
          return m + ' scale(1.25)';
        });
        te.el.style.opacity = '1';
        te.el.style.zIndex = '10';
      });
      te.el.addEventListener('mouseleave', function() {
        isHovering = false;
        te.el.style.transform = te.el.style.transform.replace(' scale(1.25)', '');
        te.el.style.zIndex = '';
        // Opacity will be reset by positionTags on next frame
      });
    });

    // Recalculate on resize
    var resizeTimeout;
    window.addEventListener('resize', function() {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(function() {
        updateRadius();
      }, 150);
    });

  })();

  // ===== TOC SIDEBAR =====
  var tocSidebar = document.getElementById('toc-sidebar');
  var tocNav = document.getElementById('toc-nav');
  if (tocSidebar && tocNav) {
    var content = document.querySelector('.content');
    if (content) {
      var headings = content.querySelectorAll('h2');
      if (headings.length) {
        headings.forEach(function(h, i) {
          var id = 'toc-' + i;
          h.id = id;
          var a = document.createElement('a');
          a.href = '#' + id;
          a.textContent = h.textContent;
          a.addEventListener('click', function(e) {
            e.preventDefault();
            h.scrollIntoView({ behavior: 'smooth' });
            history.pushState(null, '', '#' + id);
          });
          tocNav.appendChild(a);
        });
        // IntersectionObserver for scroll tracking
        if ('IntersectionObserver' in window) {
          var tocLinks = tocNav.querySelectorAll('a');
          var headingMap = {};
          tocLinks.forEach(function(link, i) {
            headingMap['toc-' + i] = link;
          });
          var tocObserver = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
              var link = headingMap[entry.target.id];
              if (!link) return;
              if (entry.isIntersecting) {
                tocLinks.forEach(function(l) { l.classList.remove('active'); });
                link.classList.add('active');
              }
            });
          }, { rootMargin: '-80px 0px -70% 0px', threshold: 0 });
          headings.forEach(function(h) { tocObserver.observe(h); });
        }
      }
    }
  }
