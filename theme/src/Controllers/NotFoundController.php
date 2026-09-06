<?php
/**
 * 404 controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Timber\Timber;

/**
 * Not found: friendly message, search form, recent stories.
 */
final class NotFoundController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		return array( '404.twig' );
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$context['recent'] = Timber::get_posts(
			array(
				'post_type'           => 'post',
				'posts_per_page'      => 3,
				'ignore_sticky_posts' => true,
				'no_found_rows'       => true,
			)
		);

		return $context;
	}
}
