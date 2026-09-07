<?php
/**
 * Global Timber context.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use Lions\Theme\Site;
use Lions\Theme\Theme;
use Timber\Timber;

/**
 * Adds what every template needs and nothing more:
 *
 * - site          Lions\Theme\Site (name, url, cta, social, contact, logo)
 * - menus         primary, legal
 * - assets        base URL for assets/
 * - theme_version for cache-busting inline references
 */
final class Context implements Registrable {

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_filter( 'timber/context', array( $this, 'extend' ) );
	}

	/**
	 * Add theme data to the global context.
	 *
	 * @param array<string, mixed> $context Timber context.
	 * @return array<string, mixed>
	 */
	public function extend( array $context ): array {
		$context['site']          = new Site();
		$context['assets']        = Theme::url( 'assets' );
		$context['theme_version'] = Theme::VERSION;
		$context['menus']         = array(
			'primary' => Timber::get_menu( Menus::PRIMARY ),
			'legal'   => Timber::get_menu( Menus::LEGAL ),
		);

		return $context;
	}
}
