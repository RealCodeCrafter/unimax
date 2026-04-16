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
      /* Do not hardcode hero background here.
         Let Elementor use the image saved in page settings. */
    }
    </style>';
}, 999);
