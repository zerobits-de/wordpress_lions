<?php
/**
 * Theme kernel.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme;

use Lions\Theme\Functions\Assets;
use Lions\Theme\Functions\Context;
use Lions\Theme\Functions\Customizer;
use Lions\Theme\Functions\Menus;
use Lions\Theme\Functions\Redirects;
use Lions\Theme\Functions\Security;
use Lions\Theme\Functions\Seo;
use Lions\Theme\Functions\ThemeSupport;
use Lions\Theme\Functions\TwigExtensions;
use Timber\Timber;

/**
 * Boots Timber and registers every piece of WordPress functionality the theme provides.
 *
 * Each feature lives in its own small class under Functions/ and exposes a
 * single `register()` method that attaches WordPress hooks. Nothing here
 * renders HTML.
 */
final class Theme {

	public const VERSION     = '1.0.2';
	public const TEXT_DOMAIN = 'lions-theme';

	/**
	 * Twig template directories, relative to the theme root, in lookup order.
	 *
	 * - templates/  page-level templates (base.twig, page.twig, ...)
	 * - views/      reusable components, partials and sections
	 */
	public const TWIG_DIRS = array( 'templates', 'views' );

	/**
	 * Singleton instance.
	 *
	 * @var Theme|null
	 */
	private static ?Theme $instance = null;

	/**
	 * Feature classes. Order matters only where hooks depend on each other
	 * (Context must run before the first Timber::context() call, which it does
	 * because it registers a filter, not a call).
	 *
	 * @var array<class-string<Registrable>>
	 */
	private const FEATURES = array(
		ThemeSupport::class,
		Menus::class,
		Assets::class,
		Customizer::class,
		Context::class,
		TwigExtensions::class,
		Seo::class,
		Security::class,
		Redirects::class,
	);

	/**
	 * Boot once.
	 */
	public static function boot(): Theme {
		if ( null === self::$instance ) {
			self::$instance = new self();
			self::$instance->register();
		}

		return self::$instance;
	}

	/**
	 * Use Theme::boot().
	 */
	private function __construct() {}

	/**
	 * Initialise Timber and register all feature classes.
	 */
	private function register(): void {
		Timber::init();
		Timber::$dirname = self::TWIG_DIRS;

		foreach ( self::FEATURES as $feature ) {
			( new $feature() )->register();
		}
	}

	/**
	 * Absolute filesystem path inside the theme.
	 *
	 * @param string $relative Path relative to the theme root.
	 */
	public static function path( string $relative = '' ): string {
		return rtrim( get_template_directory(), '/' ) . ( '' !== $relative ? '/' . ltrim( $relative, '/' ) : '' );
	}

	/**
	 * Public URL inside the theme.
	 *
	 * @param string $relative Path relative to the theme root.
	 */
	public static function url( string $relative = '' ): string {
		return rtrim( get_template_directory_uri(), '/' ) . ( '' !== $relative ? '/' . ltrim( $relative, '/' ) : '' );
	}

	/**
	 * Cache-busting version for an asset: file modification time in
	 * development, the theme version in production.
	 *
	 * @param string $relative Asset path relative to the theme root.
	 */
	public static function asset_version( string $relative ): string {
		$file = self::path( $relative );

		if ( 'production' !== wp_get_environment_type() && is_readable( $file ) ) {
			return (string) filemtime( $file );
		}

		return self::VERSION;
	}
}
