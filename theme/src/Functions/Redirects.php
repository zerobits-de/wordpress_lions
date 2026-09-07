<?php
/**
 * Canonical redirects for merged pages.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use WP_Post;

/**
 * Sends visitors of a merged page to the page that now holds the content.
 *
 * "Mitmachen" used to be a landing page above "Ehrenamt". The two are now one
 * page. The parent has to stay published, because the child's permalink is
 * built from it (and "Spenden" sits under it too), so instead of deleting it we
 * redirect it. One page, reachable under both URLs.
 */
final class Redirects implements Registrable {

	/**
	 * Parent page slug => slug of the child that holds the content.
	 */
	private const MERGED = array(
		'get-involved' => 'volunteer',
	);

	/**
	 * Whether $parent_slug is a page that merely redirects to $child_slug.
	 *
	 * Breadcrumbs use this to drop the parent when it would link straight back to
	 * the page being viewed. Siblings such as "Spenden" keep it: for them the
	 * parent is still a meaningful step up, and following it lands on the merged
	 * page rather than on itself.
	 *
	 * @param string $parent_slug Ancestor page slug.
	 * @param string $child_slug  Slug of the page being viewed.
	 */
	public static function redirects_to( string $parent_slug, string $child_slug ): bool {
		return ( self::MERGED[ $parent_slug ] ?? null ) === $child_slug;
	}

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'template_redirect', array( $this, 'redirect_merged_pages' ) );
	}

	/**
	 * Redirect a merged parent page to the child holding its content.
	 */
	public function redirect_merged_pages(): void {
		if ( ! is_page() ) {
			return;
		}

		$page = get_queried_object();

		if ( ! $page instanceof WP_Post || ! isset( self::MERGED[ $page->post_name ] ) ) {
			return;
		}

		$target = get_page_by_path( $page->post_name . '/' . self::MERGED[ $page->post_name ] );

		if ( ! $target instanceof WP_Post || 'publish' !== $target->post_status ) {
			return;
		}

		wp_safe_redirect( get_permalink( $target ), 301 );
		exit;
	}
}
