<?php
/**
 * Navigation menu locations.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;

/**
 * Registers menu locations. Editors assign menus under Appearance > Menus.
 */
final class Menus implements Registrable {

	public const PRIMARY = 'primary';
	public const LEGAL   = 'legal';

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'after_setup_theme', array( $this, 'register_locations' ) );
	}

	/**
	 * Register the menu locations.
	 */
	public function register_locations(): void {
		register_nav_menus(
			array(
				self::PRIMARY => __( 'Primary navigation', 'lions-theme' ),
				self::LEGAL   => __( 'Legal links (footer)', 'lions-theme' ),
			)
		);
	}
}
