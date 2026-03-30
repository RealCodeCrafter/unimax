<?php
/**
 * Force homepage hero visibility/background on desktop.
 * Some Elementor dumps mark the hero as hidden on large screens.
 */

add_action('wp_head', function () {
    echo '<style id="hero-desktop-force-background">
    @media (min-width:1025px){
      body.home .elementor-20 .elementor-element.elementor-element-de6d8e2.elementor-hidden-desktop{
        display:block !important;
        visibility:visible !important;
        opacity:1 !important;
      }
      body.home .elementor-20 .elementor-element.elementor-element-de6d8e2 > .elementor-container{
        min-height:500px !important;
      }
      .elementor-20 .elementor-element.elementor-element-de6d8e2:not(.elementor-motion-effects-element-type-background),
      .elementor-20 .elementor-element.elementor-element-de6d8e2 > .elementor-motion-effects-container > .elementor-motion-effects-layer{
        background-image:url("/wp-content/uploads/2023/05/new_rtg_bg2.png") !important;
        background-position:bottom center !important;
        background-repeat:no-repeat !important;
        background-size:cover !important;
      }
    }
    </style>';
}, 999);
