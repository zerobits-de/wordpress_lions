<?php
/**
 * Front page controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Lions\Theme\Content\FrontPageContent;
use Timber\Post;
use Timber\Timber;

/**
 * Homepage: hero, intro, initiatives, statistics, latest stories, call to action.
 *
 * Section data comes from FrontPageContent (placeholder copy that editors can
 * override through the "Home" page content and the Customizer). Latest stories
 * are real posts.
 */
final class FrontPageController extends AbstractController {

	/**
	 * Twig template candidates.
	 *
	 * @return array<int, string>
	 */
	protected function templates(): array {
		return array( 'front-page.twig' );
	}

	/**
	 * Template context.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		$context = parent::context();

		$page = $context['post'] ?? null;

		$content = new FrontPageContent();

		$context['hero']        = $content->hero();
		$context['intro']       = $content->intro( $page instanceof Post ? $page : null );
		$context['initiatives'] = $content->initiatives();
		$context['statistics']  = $content->statistics();
		$context['feature']     = $content->feature();
		$context['cta']         = $content->cta();
		$context['stories']     = Timber::get_posts(
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
