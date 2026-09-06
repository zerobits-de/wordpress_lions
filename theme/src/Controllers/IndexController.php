<?php
/**
 * Index controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Timber\Post;
use Timber\Timber;

/**
 * Blog index ("Stories" page) and the last-resort fallback template.
 */
final class IndexController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		return array( 'index.twig' );
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$title       = __( 'Stories', 'lions-theme' );
		$description = '';

		if ( is_home() && ! is_front_page() ) {
			$page = Timber::get_post( (int) get_option( 'page_for_posts' ) );

			if ( $page instanceof Post ) {
				$title       = $page->title();
				$description = $page->content();
			}
		}

		$context['archive'] = array(
			'title'       => $title,
			'description' => $description,
		);

		return $context;
	}
}
