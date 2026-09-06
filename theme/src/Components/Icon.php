<?php
/**
 * Inline SVG icons.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Components;

use Lions\Theme\Theme;

/**
 * Loads an SVG from assets/images/icons/{name}.svg and returns it as inline
 * markup, decorated for accessibility. Exposed to Twig as `icon('name')`.
 */
final class Icon {

	/**
	 * Loaded SVG markup keyed by icon name.
	 *
	 * @var array<string, string>
	 */
	private static array $cache = array();

	/**
	 * Render an inline SVG icon.
	 *
	 * @param string $name    Icon file name without extension (a-z, 0-9, dash).
	 * @param string $classes Extra CSS classes.
	 * @param string $label   Accessible label. Empty = decorative (aria-hidden).
	 */
	public static function render( string $name, string $classes = '', string $label = '' ): string {
		$name = strtolower( $name );

		if ( 1 !== preg_match( '/^[a-z0-9-]+$/', $name ) ) {
			return '';
		}

		if ( ! isset( self::$cache[ $name ] ) ) {
			$file = Theme::path( 'assets/images/icons/' . $name . '.svg' );

			// phpcs:ignore WordPress.WP.AlternativeFunctions.file_get_contents_file_get_contents -- local theme file.
			self::$cache[ $name ] = is_readable( $file ) ? (string) file_get_contents( $file ) : '';
		}

		$svg = self::$cache[ $name ];

		if ( '' === $svg ) {
			return '';
		}

		$class_attribute = trim( 'icon icon--' . $name . ' ' . $classes );

		$attributes  = ' class="' . esc_attr( $class_attribute ) . '" focusable="false"';
		$attributes .= '' === $label
			? ' aria-hidden="true"'
			: ' role="img" aria-label="' . esc_attr( $label ) . '"';

		return (string) preg_replace( '/<svg\b/', '<svg' . $attributes, $svg, 1 );
	}
}
