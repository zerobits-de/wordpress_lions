<?php
/**
 * Breadcrumb data.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Components;

use Timber\Post;
use Timber\Term;

/**
 * Builds the data for views/components/breadcrumb.twig.
 *
 * Returns a plain list of {title, url}; the last item has no URL.
 */
final class Breadcrumbs {

	/**
	 * Breadcrumb trail for a page or post.
	 *
	 * @param Post $post Current post.
	 * @return array<int, array{title: string, url: string|null}>
	 */
	public static function for_post( Post $post ): array {
		$items = array(
			array(
				'title' => __( 'Home', 'lions-theme' ),
				'url'   => home_url( '/' ),
			),
		);

		if ( 'page' === $post->post_type ) {
			foreach ( array_reverse( iterator_to_array( $post->ancestors(), false ) ) as $ancestor ) {
				if ( $ancestor instanceof Post ) {
					$items[] = array(
						'title' => $ancestor->title(),
						'url'   => $ancestor->link(),
					);
				}
			}
		} elseif ( 'post' === $post->post_type ) {
			$posts_page_id = (int) get_option( 'page_for_posts' );

			if ( $posts_page_id > 0 ) {
				$items[] = array(
					'title' => get_the_title( $posts_page_id ),
					'url'   => (string) get_permalink( $posts_page_id ),
				);
			}

			$category = $post->category();

			if ( $category instanceof Term ) {
				$items[] = array(
					'title' => $category->title(),
					'url'   => $category->link(),
				);
			}
		}

		$items[] = array(
			'title' => $post->title(),
			'url'   => null,
		);

		return $items;
	}
}
