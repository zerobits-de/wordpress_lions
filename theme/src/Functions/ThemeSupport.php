<?php
/**
 * Theme supports, image sizes, editor styles.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use Lions\Theme\Theme;

/**
 * Declares what the theme supports.
 */
final class ThemeSupport implements Registrable {

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'after_setup_theme', array( $this, 'setup' ) );
	}

	/**
	 * Declare theme supports, editor styles and image sizes.
	 */
	public function setup(): void {
		load_theme_textdomain( Theme::TEXT_DOMAIN, Theme::path( 'languages' ) );

		add_theme_support( 'title-tag' );
		add_theme_support( 'post-thumbnails' );
		add_theme_support( 'automatic-feed-links' );
		add_theme_support( 'responsive-embeds' );
		add_theme_support( 'align-wide' );
		add_theme_support(
			'html5',
			array( 'search-form', 'gallery', 'caption', 'style', 'script', 'navigation-widgets' )
		);
		add_theme_support(
			'custom-logo',
			array(
				'height'               => 120,
				'width'                => 360,
				'flex-height'          => true,
				'flex-width'           => true,
				'unlink-homepage-logo' => false,
			)
		);

		// Editor: same tokens and content styles as the front end.
		add_theme_support( 'editor-styles' );
		add_editor_style(
			array(
				'assets/css/tokens.css',
				'assets/css/editor.css',
			)
		);

		// Image sizes used by the Twig components (see views/components/image.twig).
		set_post_thumbnail_size( 1200, 800, true );
		add_image_size( 'lions-card', 800, 500, true );
		add_image_size( 'lions-feature', 1200, 800, true );
		add_image_size( 'lions-hero', 1920, 1080, true );

		$GLOBALS['content_width'] = 1180; // phpcs:ignore WordPress.WP.GlobalVariablesOverride.Prohibited
	}
}
