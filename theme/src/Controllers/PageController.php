<?php
/**
 * Page controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Lions\Theme\Components\Breadcrumbs;
use Timber\Post;
use Timber\Timber;

/**
 * Regular pages: breadcrumb, page header, block content, optional child-page navigation.
 */
final class PageController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		$templates = array();
		$post      = Timber::get_post();

		if ( $post instanceof Post ) {
			$templates[] = 'page-' . $post->slug . '.twig';
		}

		$templates[] = 'page.twig';

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
			$context['subpages']    = $this->subpages( $post );
		}

		return $context;
	}

	/**
	 * Sibling/child pages, used to render a section navigation on pages that
	 * belong to a hierarchy (About Us > Our History ...).
	 *
	 * @param Post $post Current page.
	 * @return array{title: string, url: string, pages: \Timber\PostCollectionInterface}|null
	 */
	private function subpages( Post $post ): ?array {
		$parent_id = $post->post_parent > 0 ? (int) $post->post_parent : $post->ID;
		$parent    = $parent_id === $post->ID ? $post : Timber::get_post( $parent_id );

		if ( ! $parent instanceof Post ) {
			return null;
		}

		$pages = Timber::get_posts(
			array(
				'post_type'      => 'page',
				'post_parent'    => $parent_id,
				'orderby'        => 'menu_order title',
				'order'          => 'ASC',
				'posts_per_page' => 20,
				'no_found_rows'  => true,
			)
		);

		if ( null === $pages || 0 === count( $pages ) ) {
			return null;
		}

		return array(
			'title' => $parent->title(),
			'url'   => $parent->link(),
			'pages' => $pages,
		);
	}
}
