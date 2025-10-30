// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mermaid from 'astro-mermaid';

// https://astro.build/config
export default defineConfig({
	site: 'https://support-kube.eliegavoty.fr',
	// base: '/', // Pas de base path avec un domaine custom
	integrations: [
		mermaid(),
		starlight({
			title: 'Formation Docker',
			description: 'Guide complet pour apprendre Docker et la conteneurisation',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/e-lie/formation-docker' }
			],
			sidebar: [
				{
					label: 'Docker - Fondamentaux',
					autogenerate: { directory: 'docker-fondamentaux' },
				},
				{
					label: 'Images & Dockerfiles',
					autogenerate: { directory: 'images-dockerfiles' },
				},
				{
					label: 'Volumes & Réseaux',
					autogenerate: { directory: 'volumes-reseaux' },
				},
				{
					label: 'Déploiement & Orchestration',
					autogenerate: { directory: 'deploiement-orchestration' },
				},
				{
					label: 'Sécurité & Observabilité',
					autogenerate: { directory: 'securite-observabilite' },
				},
				{
					label: 'CI/CD & Bonus',
					autogenerate: { directory: 'cicd-bonus' },
				},
			],
			customCss: [
				// Chemin vers votre CSS personnalisé si nécessaire
				// './src/styles/custom.css',
			],
		}),
	],
});
