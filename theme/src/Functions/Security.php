<?php
/**
 * Small hardening measures.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;

/**
 * Reduces information leakage and disables legacy endpoints the site does
 * not use. Server-level hardening (headers, TLS) belongs in the hosting layer.
 */
final class Security implements Registrable {

	/**
	 * Attach hooks and remove leaky defaults.
	 */
	public function register(): void {
		remove_action( 'wp_head', 'wp_generator' );
		remove_action( 'wp_head', 'wlwmanifest_link' );
		remove_action( 'wp_head', 'rsd_link' );

		add_filter( 'the_generator', '__return_empty_string' );
		add_filter( 'xmlrpc_enabled', '__return_false' );
		add_filter( 'login_errors', array( $this, 'generic_login_error' ) );
	}

	/**
	 * Do not reveal whether the username or the password was wrong.
	 */
	public function generic_login_error(): string {
		return __( 'The credentials you entered are not valid.', 'lions-theme' );
	}
}
