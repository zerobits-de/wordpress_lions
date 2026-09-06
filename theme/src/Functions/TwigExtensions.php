<?php
/**
 * Theme-specific Twig functions and filters.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Components\Icon;
use Lions\Theme\Registrable;
use Lions\Theme\Theme;
use Twig\Environment;
use Twig\TwigFilter;
use Twig\TwigFunction;

/**
 * Small helpers for presentation only.
 *
 *   {{ asset('images/foo.svg') }}         theme asset URL
 *   {{ icon('search', 'icon--lg') }}      inline SVG icon (decorative)
 *   {{ icon('facebook', '', 'Facebook') }} labelled icon
 *   {{ phone|tel }}                       "tel:" href from a display number
 */
final class TwigExtensions implements Registrable {

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_filter( 'timber/twig', array( $this, 'extend' ) );
	}

	/**
	 * Register functions and filters.
	 *
	 * @param Environment $twig Twig environment.
	 */
	public function extend( Environment $twig ): Environment {
		$twig->addFunction( new TwigFunction( 'asset', array( $this, 'asset' ) ) );
		$twig->addFunction( new TwigFunction( 'icon', array( Icon::class, 'render' ), array( 'is_safe' => array( 'html' ) ) ) );
		$twig->addFilter( new TwigFilter( 'tel', array( $this, 'tel' ) ) );

		return $twig;
	}

	/**
	 * URL of a file in assets/.
	 *
	 * @param string $relative Path relative to assets/.
	 */
	public function asset( string $relative ): string {
		return Theme::url( 'assets/' . ltrim( $relative, '/' ) );
	}

	/**
	 * Build a tel: href from a display phone number.
	 *
	 * @param string $number Phone number as displayed.
	 */
	public function tel( string $number ): string {
		return 'tel:' . (string) preg_replace( '/[^0-9+]/', '', $number );
	}
}
