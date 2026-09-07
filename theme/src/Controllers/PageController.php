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
 * Regular pages: breadcrumb, page header, block content.
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
		}

		return $context;
	}
}
