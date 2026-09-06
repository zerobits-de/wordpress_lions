<?php
/**
 * Search controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

/**
 * Search results.
 */
final class SearchController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		return array( 'search.twig' );
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$query = get_search_query( false );

		$context['search'] = array(
			'query' => $query,
			'total' => (int) ( $GLOBALS['wp_query']->found_posts ?? 0 ),
		);

		return $context;
	}
}
