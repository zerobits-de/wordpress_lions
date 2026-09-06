<?php
/**
 * Theme bootstrap.
 *
 * Bootstrap chain: functions.php -> Composer autoload -> Lions\Theme\Theme::boot() -> Timber -> WordPress hooks.
 *
 * Presentation lives in Twig (templates/, views/). PHP only prepares data.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

$lions_autoload = __DIR__ . '/vendor/autoload.php';

if ( ! is_readable( $lions_autoload ) ) {
	/**
	 * Composer dependencies are missing. Explain how to fix it instead of
	 * fataling with an obscure "class not found" error.
	 */
	$lions_missing_dependencies = static function (): string {
		return sprintf(
			/* translators: %s: composer command */
			esc_html__( 'The Lions International theme is missing its Composer dependencies. Run %s inside the theme directory (or use "make composer" in the project root).', 'lions-theme' ),
			'<code>composer install</code>'
		);
	};

	add_action(
		'admin_notices',
		static function () use ( $lions_missing_dependencies ): void {
			echo '<div class="notice notice-error"><p>' . wp_kses( $lions_missing_dependencies(), array( 'code' => array() ) ) . '</p></div>';
		}
	);

	add_action(
		'template_redirect',
		static function () use ( $lions_missing_dependencies ): void {
			wp_die(
				wp_kses( $lions_missing_dependencies(), array( 'code' => array() ) ),
				esc_html__( 'Theme dependencies missing', 'lions-theme' ),
				array( 'response' => 500 )
			);
		}
	);

	return;
}

require_once $lions_autoload;

Lions\Theme\Theme::boot();
