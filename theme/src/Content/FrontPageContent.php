<?php
/**
 * Front page content provider.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Content;

use Lions\Theme\Functions\Customizer;
use Lions\Theme\Theme;
use Timber\Image;
use Timber\Post;
use Timber\Timber;

/**
 * Original placeholder copy for the homepage sections.
 *
 * Why this exists: the homepage is a composed landing page, not a single
 * block of editor content. Until a dedicated editing UI (blocks or fields)
 * is added, the section data is defined here so Twig stays free of content
 * and editors can already override the intro through the "Home" page.
 *
 * All text is original placeholder copy. Nothing is copied from lionsclubs.org.
 */
final class FrontPageContent {

	/**
	 * Hero section.
	 *
	 * @return array<string, mixed>
	 */
	public function hero(): array {
		return array(
			'eyebrow'  => '',
			'title'    => __( 'Together, we serve where we are needed most.', 'lions-theme' ),
			'subtitle' => __( 'Small acts. Global reach.', 'lions-theme' ),
			'images'   => $this->hero_images(),
			'actions'  => array(
				array(
					'label'   => __( 'Become a member', 'lions-theme' ),
					'url'     => Customizer::mod( 'cta_join_url' ),
					'variant' => 'accent',
				),
			),
		);
	}

	/**
	 * Background images for the hero, chosen in the Customizer.
	 *
	 * Returns Timber images for the attachments an editor picked, so the hero can
	 * cross-fade them, and falls back to the single theme placeholder when none
	 * are set.
	 *
	 * @return array<int, Image|array{src: string, alt: string}>
	 */
	private function hero_images(): array {
		$images = array();

		foreach ( Customizer::hero_image_ids() as $id ) {
			$image = Timber::get_image( $id );

			if ( $image instanceof Image ) {
				$images[] = $image;
			}
		}

		if ( array() === $images ) {
			$images[] = array(
				'src' => Theme::url( 'assets/images/placeholders/hero.svg' ),
				'alt' => '',
			);
		}

		return $images;
	}

	/**
	 * Intro: editors control it through the "Home" page content. Falls back to
	 * placeholder copy when that page is empty.
	 *
	 * @param Post|null $page The front page post, if any.
	 * @return array{title: string, body: string, image: array{src: string, alt: string}, action: array{label: string, url: string, variant: string}}
	 */
	public function intro( ?Post $page ): array {
		$body = '';

		if ( $page instanceof Post ) {
			$body = trim( (string) $page->content() );
		}

		if ( '' === $body ) {
			$body = '<p>' . esc_html__( 'Seventeen members founded Lions Club Musterstadt in January 1983. Ever since, the club has helped where help is needed in Musterstadt and the surrounding Verbandsgemeinde, guided by one motto: We serve.', 'lions-theme' ) . '</p>'
				. '<p>' . esc_html__( 'The Inclusion Cup, the advent calendar campaign and our benefit concerts fund very concrete things: school projects, sports equipment, and support for people with disabilities in the region.', 'lions-theme' ) . '</p>';
		}

		return array(
			'title'  => __( 'Serving Musterstadt since 1983', 'lions-theme' ),
			'body'   => $body,
			'image'  => array(
				'src' => Theme::url( 'assets/images/placeholders/feature-1.svg' ),
				'alt' => '',
			),
			'action' => array(
				'label'   => __( 'More about the club', 'lions-theme' ),
				'url'     => $this->page_url( 'our-history', '/our-history/' ),
				'variant' => 'primary',
			),
		);
	}

	/**
	 * Impact figures. Placeholder values; replace with verified numbers.
	 *
	 * @return array{title: string, items: array<int, array{value: string, label: string, tone: string}>}
	 */
	public function statistics(): array {
		return array(
			'title' => __( 'Service at scale', 'lions-theme' ),
			'items' => array(
				array(
					'value' => '1.4M',
					'label' => __( 'members worldwide', 'lions-theme' ),
					'tone'  => 'navy',
				),
				array(
					'value' => '49K',
					'label' => __( 'local clubs', 'lions-theme' ),
					'tone'  => 'purple',
				),
				array(
					'value' => '200+',
					'label' => __( 'countries and areas', 'lions-theme' ),
					'tone'  => 'blue',
				),
				array(
					'value' => '100+',
					'label' => __( 'years of service', 'lions-theme' ),
					'tone'  => 'gradient',
				),
			),
		);
	}

	/**
	 * Posts that should appear on the homepage as photo lockups.
	 *
	 * Editors choose the category in the Customizer; every post in it becomes a
	 * block laid out like the intro lockup. Blocks alternate sides, the first one
	 * mirroring the intro block above them, and posts without a featured image
	 * fall back to the theme placeholder so no block renders empty.
	 *
	 * @return array<int, array<string, mixed>>
	 */
	public function feature_posts(): array {
		$category_id = Customizer::feature_category_id();

		if ( 0 === $category_id ) {
			return array();
		}

		$posts = Timber::get_posts(
			array(
				'post_type'      => 'post',
				'posts_per_page' => -1,
				'category__in'   => array( $category_id ),
				'no_found_rows'  => true,
			)
		);

		$blocks = array();

		foreach ( $posts as $post ) {
			if ( ! $post instanceof Post ) {
				continue;
			}

			$thumbnail = $post->thumbnail();

			$blocks[] = array(
				'id'      => 'feature-' . $post->ID,
				// Decoded to plain text because sections/feature.twig escapes the
				// title itself; passing the filtered title would double-encode it.
				'title'   => html_entity_decode( wp_strip_all_tags( $post->title() ), ENT_QUOTES, 'UTF-8' ),
				'body'    => '<p>' . $post->excerpt(
					array(
						'words'     => 40,
						'read_more' => '',
					)
				) . '</p>',
				'image'   => $thumbnail instanceof Image ? $thumbnail : array(
					'src' => Theme::url( 'assets/images/placeholders/story.svg' ),
					'alt' => '',
				),
				'action'  => array(
					'label'   => __( 'Read more', 'lions-theme' ),
					'url'     => (string) $post->link(),
					'variant' => 'purple',
				),
				'reverse' => 0 === count( $blocks ) % 2,
			);
		}

		return $blocks;
	}

	/**
	 * Closing call to action.
	 *
	 * @return array<string, mixed>
	 */
	public function cta(): array {
		return array(
			'title'   => __( 'Ready to make a difference?', 'lions-theme' ),
			'text'    => __( 'Get to know Lions Club Musterstadt as our guest.', 'lions-theme' ),
			'actions' => array(
				array(
					'label'   => __( 'Become a member', 'lions-theme' ),
					'url'     => Customizer::mod( 'cta_join_url' ),
					'variant' => 'accent',
				),
			),
		);
	}

	/**
	 * URL of a page by slug, or a fallback path when the page does not exist yet.
	 *
	 * @param string $slug     Page slug.
	 * @param string $fallback Fallback path relative to the home URL.
	 */
	private function page_url( string $slug, string $fallback ): string {
		$page = get_page_by_path( $slug );

		if ( $page instanceof \WP_Post ) {
			return (string) get_permalink( $page );
		}

		return home_url( $fallback );
	}
}
