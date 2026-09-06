<?php
/**
 * Front-end assets.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use Lions\Theme\Theme;

/**
 * Enqueues the design-system stylesheets and the single, deferred script.
 *
 * Stylesheets are ordered: tokens -> base -> layout -> header/footer ->
 * components -> sections -> content. Keep the order; later files rely on
 * earlier custom properties.
 */
final class Assets implements Registrable {

	/**
	 * Stylesheet basenames in load order.
	 *
	 * @var array<int, string>
	 */
	private const STYLES = array(
		'tokens',
		'base',
		'layout',
		'header',
		'footer',
		'components',
		'sections',
		'content',
	);

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'wp_enqueue_scripts', array( $this, 'enqueue' ) );
	}

	/**
	 * Enqueue stylesheets and the main script.
	 */
	public function enqueue(): void {
		$previous = array();

		foreach ( self::STYLES as $name ) {
			$relative = 'assets/css/' . $name . '.css';
			$handle   = 'lions-' . $name;

			wp_enqueue_style( $handle, Theme::url( $relative ), $previous, Theme::asset_version( $relative ) );

			$previous = array( $handle );
		}

		$script = 'assets/js/main.js';

		wp_enqueue_script(
			'lions-main',
			Theme::url( $script ),
			array(),
			Theme::asset_version( $script ),
			array(
				'strategy'  => 'defer',
				'in_footer' => true,
			)
		);

		// Not used by this theme; removing it avoids an unused request.
		wp_dequeue_style( 'classic-theme-styles' );
	}
}
