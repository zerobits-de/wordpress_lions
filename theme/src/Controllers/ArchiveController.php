<?php
/**
 * Archive controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

/**
 * Category, tag, date and author archives.
 */
final class ArchiveController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		$templates = array();

		if ( is_category() ) {
			$templates[] = 'archive-category.twig';
		} elseif ( is_tag() ) {
			$templates[] = 'archive-tag.twig';
		} elseif ( is_author() ) {
			$templates[] = 'archive-author.twig';
		}

		$templates[] = 'archive.twig';
		$templates[] = 'index.twig';

		return $templates;
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$context['archive'] = array(
			'title'       => wp_strip_all_tags( get_the_archive_title() ),
			'description' => get_the_archive_description(),
		);

		return $context;
	}
}
