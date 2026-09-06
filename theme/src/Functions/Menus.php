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

	public const PRIMARY  = 'primary';
	public const UTILITY  = 'utility';
	public const FOOTER_1 = 'footer_1';
	public const FOOTER_2 = 'footer_2';
	public const FOOTER_3 = 'footer_3';
	public const LEGAL    = 'legal';

	/**
	 * Footer column locations in display order.
	 *
	 * @var array<int, string>
	 */
	public const FOOTER_LOCATIONS = array(
		self::FOOTER_1,
		self::FOOTER_2,
		self::FOOTER_3,
	);

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
				self::PRIMARY  => __( 'Primary navigation', 'lions-theme' ),
				self::UTILITY  => __( 'Utility bar (top links)', 'lions-theme' ),
				self::FOOTER_1 => __( 'Footer column 1', 'lions-theme' ),
				self::FOOTER_2 => __( 'Footer column 2', 'lions-theme' ),
				self::FOOTER_3 => __( 'Footer column 3', 'lions-theme' ),
				self::LEGAL    => __( 'Legal links (footer bottom)', 'lions-theme' ),
			)
		);
	}
}
