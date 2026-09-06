<?php
/**
 * Single post controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Lions\Theme\Components\Breadcrumbs;
use Timber\Post;
use Timber\Timber;

/**
 * Single posts (stories): article layout plus related stories.
 */
final class SingleController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		$templates = array();
		$post      = Timber::get_post();

		if ( $post instanceof Post ) {
			$templates[] = 'single-' . $post->post_type . '.twig';
		}

		$templates[] = 'single.twig';

		return $templates;
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$post = $context['post'] ?? null;

		if ( $post instanceof Post ) {
			$context['breadcrumbs'] = Breadcrumbs::for_post( $post );
			$context['related']     = $this->related( $post );
		}

		return $context;
	}

	/**
	 * Up to three posts sharing a category with the current one.
	 *
	 * @param Post $post Current post.
	 */
	private function related( Post $post ): ?\Timber\PostCollectionInterface {
		$category_ids = wp_get_post_categories( $post->ID, array( 'fields' => 'ids' ) );

		$args = array(
			'post_type'      => 'post',
			'posts_per_page' => 3,
			'post__not_in'   => array( $post->ID ),
			'no_found_rows'  => true,
		);

		if ( is_array( $category_ids ) && array() !== $category_ids ) {
			$args['category__in'] = array_map( 'intval', $category_ids );
		}

		return Timber::get_posts( $args );
	}
}
