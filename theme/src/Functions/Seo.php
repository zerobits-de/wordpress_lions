<?php
/**
 * Technical SEO foundations.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use Lions\Theme\Site;

/**
 * Open Graph / Twitter card meta and Organization/WebSite JSON-LD.
 *
 * Steps aside automatically when a known SEO plugin is active so the two do
 * not emit duplicate tags.
 */
final class Seo implements Registrable {

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'wp_head', array( $this, 'meta' ), 5 );
		add_action( 'wp_head', array( $this, 'json_ld' ), 6 );
	}

	/**
	 * Whether a known SEO plugin handles meta tags.
	 */
	private function has_seo_plugin(): bool {
		return defined( 'WPSEO_VERSION' )
			|| defined( 'AIOSEO_VERSION' )
			|| defined( 'RANK_MATH_VERSION' )
			|| defined( 'SEOPRESS_VERSION' )
			|| class_exists( 'The_SEO_Framework\\Load' );
	}

	/**
	 * Print Open Graph and Twitter card meta tags.
	 */
	public function meta(): void {
		if ( $this->has_seo_plugin() ) {
			return;
		}

		$title       = wp_get_document_title();
		$description = $this->description();
		$url         = $this->current_url();
		$image       = $this->image();
		$type        = is_singular( 'post' ) ? 'article' : 'website';

		$tags = array(
			array( 'property', 'og:site_name', get_bloginfo( 'name' ) ),
			array( 'property', 'og:type', $type ),
			array( 'property', 'og:title', $title ),
			array( 'property', 'og:url', $url ),
			array( 'property', 'og:locale', get_locale() ),
			array( 'name', 'twitter:card', '' !== $image ? 'summary_large_image' : 'summary' ),
			array( 'name', 'twitter:title', $title ),
		);

		if ( '' !== $description ) {
			$tags[] = array( 'name', 'description', $description );
			$tags[] = array( 'property', 'og:description', $description );
			$tags[] = array( 'name', 'twitter:description', $description );
		}

		if ( '' !== $image ) {
			$tags[] = array( 'property', 'og:image', $image );
			$tags[] = array( 'name', 'twitter:image', $image );
		}

		foreach ( $tags as list( $attribute, $key, $value ) ) {
			printf(
				'<meta %s="%s" content="%s">' . "\n",
				esc_attr( $attribute ),
				esc_attr( $key ),
				esc_attr( $value )
			);
		}
	}

	/**
	 * Print Organization and WebSite structured data on the front page.
	 */
	public function json_ld(): void {
		if ( $this->has_seo_plugin() || ! is_front_page() ) {
			return;
		}

		$site    = new Site();
		$contact = $site->contact();
		$logo    = $site->logo();

		$organization = array(
			'@type' => 'Organization',
			'name'  => '' !== $contact['organization'] ? $contact['organization'] : get_bloginfo( 'name' ),
			'url'   => home_url( '/' ),
		);

		if ( null !== $logo ) {
			$organization['logo'] = $logo->src();
		}

		$same_as = array_column( $site->social(), 'url' );

		if ( array() !== $same_as ) {
			$organization['sameAs'] = $same_as;
		}

		if ( '' !== $contact['phone'] ) {
			$organization['telephone'] = $contact['phone'];
		}

		$graph = array(
			'@context' => 'https://schema.org',
			'@graph'   => array(
				$organization,
				array(
					'@type'           => 'WebSite',
					'name'            => get_bloginfo( 'name' ),
					'url'             => home_url( '/' ),
					'potentialAction' => array(
						'@type'       => 'SearchAction',
						'target'      => home_url( '/?s={search_term_string}' ),
						'query-input' => 'required name=search_term_string',
					),
				),
			),
		);

		echo '<script type="application/ld+json">' . wp_json_encode( $graph, JSON_UNESCAPED_SLASHES ) . '</script>' . "\n";
	}

	/**
	 * Meta description for the current request.
	 */
	private function description(): string {
		if ( is_singular() ) {
			$post = get_queried_object();

			if ( $post instanceof \WP_Post ) {
				$text = '' !== $post->post_excerpt ? $post->post_excerpt : $post->post_content;

				return wp_trim_words( wp_strip_all_tags( strip_shortcodes( $text ) ), 30, '…' );
			}
		}

		if ( is_front_page() ) {
			return (string) get_bloginfo( 'description' );
		}

		if ( is_archive() ) {
			return wp_trim_words( wp_strip_all_tags( get_the_archive_description() ), 30, '…' );
		}

		return '';
	}

	/**
	 * Share image URL for the current request.
	 */
	private function image(): string {
		if ( is_singular() && has_post_thumbnail() ) {
			$src = get_the_post_thumbnail_url( null, 'large' );

			return is_string( $src ) ? $src : '';
		}

		return '';
	}

	/**
	 * Canonical-ish URL of the current request.
	 */
	private function current_url(): string {
		if ( is_singular() ) {
			return (string) get_permalink();
		}

		if ( is_front_page() ) {
			return home_url( '/' );
		}

		global $wp;

		return home_url( add_query_arg( array(), $wp->request ?? '' ) );
	}
}
