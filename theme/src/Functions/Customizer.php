<?php
/**
 * Customizer settings for organisation data.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use WP_Customize_Manager;
use WP_Customize_Media_Control;

/**
 * "Lions International" panel in Appearance > Customize.
 *
 * Editors manage the homepage hero background, calls to action, social profiles
 * and contact details here without touching templates. Text values are read via
 * Customizer::mod(), the hero images via Customizer::hero_image_ids().
 */
final class Customizer implements Registrable {

	private const PANEL = 'lions';

	/**
	 * How many background images the homepage hero accepts.
	 */
	public const HERO_IMAGES = 3;

	/**
	 * Setting definitions: id => [label, section, type, default, sanitize].
	 *
	 * @return array<string, array{label: string, section: string, type: string, default: string, sanitize: callable}>
	 */
	private static function settings(): array {
		return array(
			'cta_join_url'         => array(
				'label'    => __( 'Join URL', 'lions-theme' ),
				'section'  => 'cta',
				'type'     => 'url',
				'default'  => home_url( '/get-involved/' ),
				'sanitize' => 'esc_url_raw',
			),
			'cta_donate_url'       => array(
				'label'    => __( 'Donate URL', 'lions-theme' ),
				'section'  => 'cta',
				'type'     => 'url',
				'default'  => home_url( '/get-involved/donate/' ),
				'sanitize' => 'esc_url_raw',
			),
			'social_facebook'      => array(
				'label'    => 'Facebook',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'social_instagram'     => array(
				'label'    => 'Instagram',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'contact_organization' => array(
				'label'    => __( 'Organisation name', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'text',
				'default'  => __( 'Lions International', 'lions-theme' ),
				'sanitize' => 'sanitize_text_field',
			),
			'contact_phone'        => array(
				'label'    => __( 'Phone', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'text',
				'default'  => '+1 555 0100',
				'sanitize' => 'sanitize_text_field',
			),
			'contact_email'        => array(
				'label'    => __( 'Email', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'email',
				'default'  => 'info@example.org',
				'sanitize' => 'sanitize_email',
			),
		);
	}

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'customize_register', array( $this, 'customize_register' ) );
	}

	/**
	 * Read a theme mod with the documented default.
	 *
	 * @param string $id Setting id without the `lions_` prefix.
	 */
	public static function mod( string $id ): string {
		$settings = self::settings();

		if ( ! isset( $settings[ $id ] ) ) {
			return '';
		}

		$value = get_theme_mod( 'lions_' . $id, $settings[ $id ]['default'] );

		return is_string( $value ) ? $value : '';
	}

	/**
	 * Register panel, sections, settings and controls.
	 *
	 * @param WP_Customize_Manager $wp_customize Customizer manager.
	 */
	public function customize_register( WP_Customize_Manager $wp_customize ): void {
		$wp_customize->add_panel(
			self::PANEL,
			array(
				'title'    => __( 'Lions International', 'lions-theme' ),
				'priority' => 30,
			)
		);

		$sections = array(
			'hero'     => array(
				'title'       => __( 'Homepage hero', 'lions-theme' ),
				'description' => sprintf(
					/* translators: %d: maximum number of hero background images. */
					__( 'Up to %d background images for the homepage hero. Leave a slot empty to skip it. With more than one image they cross-fade; with none the theme placeholder is used.', 'lions-theme' ),
					self::HERO_IMAGES
				),
			),
			'features' => array(
				'title'       => __( 'Homepage feature blocks', 'lions-theme' ),
				'description' => __( 'Posts in the chosen category are shown on the homepage as large photo blocks, the same layout as the intro block. Assign a post to that category to add a block; remove it to take the block away. Choose "None" to show no blocks at all.', 'lions-theme' ),
			),
			'cta'      => array(
				'title'       => __( 'Calls to action', 'lions-theme' ),
				'description' => '',
			),
			'social'   => array(
				'title'       => __( 'Social profiles', 'lions-theme' ),
				'description' => '',
			),
			'contact'  => array(
				'title'       => __( 'Contact & legal', 'lions-theme' ),
				'description' => '',
			),
		);

		foreach ( $sections as $id => $section ) {
			$wp_customize->add_section(
				self::PANEL . '_' . $id,
				array(
					'title'       => $section['title'],
					'description' => $section['description'],
					'panel'       => self::PANEL,
				)
			);
		}

		$this->register_hero_images( $wp_customize );
		$this->register_feature_category( $wp_customize );

		foreach ( self::settings() as $id => $setting ) {
			$wp_customize->add_setting(
				'lions_' . $id,
				array(
					'type'              => 'theme_mod',
					'default'           => $setting['default'],
					'sanitize_callback' => $setting['sanitize'],
				)
			);

			$wp_customize->add_control(
				'lions_' . $id,
				array(
					'label'   => $setting['label'],
					'section' => self::PANEL . '_' . $setting['section'],
					'type'    => $setting['type'],
				)
			);
		}
	}

	/**
	 * Attachment IDs chosen for the homepage hero background, in order.
	 *
	 * Empty slots are skipped, so picking only image 2 still yields one image.
	 *
	 * @return array<int, int>
	 */
	public static function hero_image_ids(): array {
		$ids = array();

		for ( $i = 1; $i <= self::HERO_IMAGES; $i++ ) {
			$id = (int) get_theme_mod( 'lions_hero_image_' . $i, 0 );

			if ( $id > 0 && 'attachment' === get_post_type( $id ) ) {
				$ids[] = $id;
			}
		}

		return $ids;
	}

	/**
	 * Category whose posts are rendered as homepage feature blocks.
	 *
	 * Returns 0 when no category is chosen or the chosen one no longer exists.
	 */
	public static function feature_category_id(): int {
		$id = absint( get_theme_mod( 'lions_feature_category', 0 ) );

		if ( 0 === $id || ! get_term( $id, 'category' ) instanceof \WP_Term ) {
			return 0;
		}

		return $id;
	}

	/**
	 * Keep only the ID of a category that actually exists.
	 *
	 * @param mixed $value Raw setting value.
	 */
	public static function sanitize_category_id( $value ): string {
		$id = absint( $value );

		return get_term( $id, 'category' ) instanceof \WP_Term ? (string) $id : '0';
	}

	/**
	 * Category picker deciding which posts become homepage feature blocks.
	 *
	 * @param WP_Customize_Manager $wp_customize Customizer manager.
	 */
	private function register_feature_category( WP_Customize_Manager $wp_customize ): void {
		$choices = array( '0' => __( '— None —', 'lions-theme' ) );

		foreach ( get_categories( array( 'hide_empty' => false ) ) as $category ) {
			$choices[ (string) $category->term_id ] = $category->name;
		}

		$wp_customize->add_setting(
			'lions_feature_category',
			array(
				'type'              => 'theme_mod',
				'default'           => '0',
				'sanitize_callback' => array( self::class, 'sanitize_category_id' ),
			)
		);

		$wp_customize->add_control(
			'lions_feature_category',
			array(
				'label'   => __( 'Category', 'lions-theme' ),
				'section' => self::PANEL . '_features',
				'type'    => 'select',
				'choices' => $choices,
			)
		);
	}

	/**
	 * Media library pickers for the homepage hero background.
	 *
	 * Stored as attachment IDs (not URLs) so Timber can generate the `lions-hero`
	 * size and a srcset for each one.
	 *
	 * @param WP_Customize_Manager $wp_customize Customizer manager.
	 */
	private function register_hero_images( WP_Customize_Manager $wp_customize ): void {
		for ( $i = 1; $i <= self::HERO_IMAGES; $i++ ) {
			$id = 'lions_hero_image_' . $i;

			$wp_customize->add_setting(
				$id,
				array(
					'type'              => 'theme_mod',
					// A string default: WP_Customize_Manager::add_setting() is typed for
					// string defaults. absint() turns the stored value back into an ID.
					'default'           => '0',
					'sanitize_callback' => 'absint',
				)
			);

			$wp_customize->add_control(
				new WP_Customize_Media_Control(
					$wp_customize,
					$id,
					array(
						'label'     => sprintf(
							/* translators: %d: position of the image in the hero background. */
							__( 'Background image %d', 'lions-theme' ),
							$i
						),
						'section'   => self::PANEL . '_hero',
						'mime_type' => 'image',
					)
				)
			);
		}
	}
}
