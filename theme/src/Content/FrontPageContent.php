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
use Timber\Post;

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
			'image'    => array(
				'src' => Theme::url( 'assets/images/placeholders/hero.svg' ),
				'alt' => '',
			),
			'actions'  => array(
				array(
					'label'   => __( 'Become a member', 'lions-theme' ),
					'url'     => Customizer::mod( 'cta_join_url' ),
					'variant' => 'accent',
				),
				array(
					'label'   => __( 'See our impact', 'lions-theme' ),
					'url'     => $this->page_url( 'our-impact', '/our-impact/' ),
					'variant' => 'outline-light',
				),
			),
		);
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
			$body = '<p>' . esc_html__( 'Lions are neighbours, colleagues and friends who decided that the best answer to a local need is to roll up their sleeves. Clubs in more than two hundred countries and geographic areas bring people together around one simple idea: communities improve when people serve them.', 'lions-theme' ) . '</p>'
				. '<p>' . esc_html__( 'From sight screenings and food drives to youth programmes and disaster response, every project starts with someone who cares. Our foundation amplifies that care with grants that turn local ideas into lasting change.', 'lions-theme' ) . '</p>';
		}

		return array(
			'title'  => __( 'United in service', 'lions-theme' ),
			'body'   => $body,
			'image'  => array(
				'src' => Theme::url( 'assets/images/placeholders/feature-1.svg' ),
				'alt' => '',
			),
			'action' => array(
				'label'   => __( 'About Lions', 'lions-theme' ),
				'url'     => $this->page_url( 'about-us', '/about-us/' ),
				'variant' => 'primary',
			),
		);
	}

	/**
	 * Key areas / global causes.
	 *
	 * @return array{title: string, intro: string, items: array<int, array<string, mixed>>}
	 */
	public function initiatives(): array {
		$items = array(
			array(
				'title'  => __( 'Vision', 'lions-theme' ),
				'text'   => __( 'Preventing avoidable blindness and supporting people with low vision through screenings, surgeries and equipment.', 'lions-theme' ),
				'accent' => 'blue',
				'image'  => 'card-1',
			),
			array(
				'title'  => __( 'Youth', 'lions-theme' ),
				'text'   => __( 'Leadership programmes, scholarships and Leo clubs that give young people a way to lead through service.', 'lions-theme' ),
				'accent' => 'green',
				'image'  => 'card-2',
			),
			array(
				'title'  => __( 'Hunger', 'lions-theme' ),
				'text'   => __( 'Food banks, school meals and community gardens that make sure no neighbour goes without a meal.', 'lions-theme' ),
				'accent' => 'purple',
				'image'  => 'card-3',
			),
			array(
				'title'  => __( 'Environment', 'lions-theme' ),
				'text'   => __( 'Tree planting, clean-up days and conservation projects that protect the places we share.', 'lions-theme' ),
				'accent' => 'yellow',
				'image'  => 'card-4',
			),
		);

		foreach ( $items as &$item ) {
			$slug          = sanitize_title( $item['title'] );
			$item['url']   = $this->page_url( $slug, '/our-impact/' . $slug . '/' );
			$item['image'] = array(
				'src' => Theme::url( 'assets/images/placeholders/' . $item['image'] . '.svg' ),
				'alt' => '',
			);
			$item['label'] = __( 'Learn more', 'lions-theme' );
		}
		unset( $item );

		return array(
			'title' => __( 'Where we focus', 'lions-theme' ),
			'intro' => __( 'Our global causes give every club a shared direction while leaving room for local priorities.', 'lions-theme' ),
			'items' => $items,
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
	 * Secondary photo lockup (image right).
	 *
	 * @return array<string, mixed>
	 */
	public function feature(): array {
		return array(
			'title'   => __( 'Ways to get involved', 'lions-theme' ),
			'body'    => '<p>' . esc_html__( 'Join a club near you, volunteer for a single project, or support the foundation. Whatever your time and talents, there is a place for you.', 'lions-theme' ) . '</p>',
			'image'   => array(
				'src' => Theme::url( 'assets/images/placeholders/feature-2.svg' ),
				'alt' => '',
			),
			'reverse' => true,
			'action'  => array(
				'label'   => __( 'Get involved', 'lions-theme' ),
				'url'     => $this->page_url( 'get-involved', '/get-involved/' ),
				'variant' => 'purple',
			),
		);
	}

	/**
	 * Closing call to action.
	 *
	 * @return array<string, mixed>
	 */
	public function cta(): array {
		return array(
			'title'   => __( 'Ready to make a difference?', 'lions-theme' ),
			'text'    => __( 'Find a club, meet your neighbours and start serving this month.', 'lions-theme' ),
			'actions' => array(
				array(
					'label'   => __( 'Find a club', 'lions-theme' ),
					'url'     => Customizer::mod( 'cta_join_url' ),
					'variant' => 'accent',
				),
				array(
					'label'   => __( 'Donate', 'lions-theme' ),
					'url'     => Customizer::mod( 'cta_donate_url' ),
					'variant' => 'outline-light',
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
