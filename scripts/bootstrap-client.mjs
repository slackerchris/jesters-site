#!/usr/bin/env node

import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

function parseArgs(argv) {
	const parsed = {};

	for (let index = 0; index < argv.length; index += 1) {
		const token = argv[index];
		if (!token.startsWith('--')) {
			continue;
		}

		const key = token.slice(2);
		const next = argv[index + 1];
		if (!next || next.startsWith('--')) {
			parsed[key] = 'true';
			continue;
		}

		parsed[key] = next;
		index += 1;
	}

	return parsed;
}

function toSlug(value) {
	return value
		.toLowerCase()
		.trim()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/(^-|-$)/g, '');
}

function normalizeUrl(value, fallback) {
	if (!value) {
		return fallback;
	}

	if (value.startsWith('http://') || value.startsWith('https://')) {
		return value;
	}

	return `https://${value}`;
}

function locationToStoreProfile(location) {
	const { slug: _slug, status: _status, landingSummary: _landingSummary, ...profile } = location;
	void _slug;
	void _status;
	void _landingSummary;
	return profile;
}

function usage() {
	return [
		'Usage:',
		'  npm run new:client -- --name "Business Name" --slug "location-slug" [options]',
		'',
		'Required:',
		'  --name          Business name used across the site',
		'  --slug          URL slug for the primary location',
		'',
		'Optional:',
		'  --locations     Number of locations to generate (default: 1)',
		'  --tagline       Hero and listing tagline',
		'  --status        Open | Opening Soon (default: Open)',
		'  --summary       Landing summary sentence',
		'  --city          Default: Your City',
		'  --state         Default: ST',
		'  --street        Default: 123 Main St',
		'  --postal        Default: 00000',
		'  --country       Default: US',
		'  --phone         Default: (000) 000-0000',
		'  --email         Default: owner@example.com',
		'  --website       Default: https://example.com',
		'  --facebook      Default: https://facebook.com',
		'  --domain        Customer domain used for env template, example: customer.com',
		'  --cms-domain    CMS domain for env template, example: cms.customer.com',
		'  --letsencrypt-email  Email for certificate notices',
		'  --help          Show this message',
		''
	].join('\n');
}

async function main() {
	const args = parseArgs(process.argv.slice(2));
	if (args.help === 'true') {
		console.log(usage());
		return;
	}

	const name = args.name?.trim();
	const slug = toSlug(args.slug || '');

	if (!name || !slug) {
		console.error('Missing required --name or --slug.');
		console.log(usage());
		process.exitCode = 1;
		return;
	}

	const city = args.city || 'Your City';
	const region = args.state || 'ST';
	const streetAddress = args.street || '123 Main St';
	const postalCode = args.postal || '00000';
	const countryCode = args.country || 'US';
	const phone = args.phone || '(000) 000-0000';
	const email = args.email || 'owner@example.com';
	const websiteUrl = normalizeUrl(args.website, 'https://example.com');
	const facebookPageUrl = normalizeUrl(args.facebook, 'https://facebook.com');
	const tagline = args.tagline || 'Local store updates, services, and community events.';
	const status = args.status || 'Open';
	const landingSummary = args.summary || `Local updates and services for ${city}.`;
	const parsedLocationCount = Number.parseInt(args.locations || '1', 10);
	const locationCount = Number.isNaN(parsedLocationCount) ? 1 : parsedLocationCount;

	if (locationCount < 1 || locationCount > 25) {
		console.error('Invalid --locations value. Use a number between 1 and 25.');
		process.exitCode = 1;
		return;
	}

	function createLocation(index) {
		const isPrimaryLocation = index === 1;
		const locationSlug = isPrimaryLocation ? slug : `${slug}-${index}`;
		const locationName = isPrimaryLocation ? name : `${name} - Location ${index}`;
		const locationSummary =
			isPrimaryLocation
				? landingSummary
				: `Location ${index} summary for ${city}. Update this after onboarding.`;
		const mapQuery = encodeURIComponent(`${streetAddress}, ${city}, ${region}, ${postalCode}`);
		const mapsUrl = `https://maps.google.com/?q=${mapQuery}`;
		const mapsEmbedUrl = `https://www.google.com/maps?q=${mapQuery}&output=embed`;
		const areaSuffix = isPrimaryLocation ? '' : `-${index}`;

		return {
			slug: locationSlug,
			status,
			landingSummary: locationSummary,
			name: locationName,
			tagline,
			websiteUrl,
			phone,
			email,
			priceRange: '$$',
			address: {
				streetAddress,
				city,
				region,
				postalCode,
				countryCode
			},
			facebookPageUrl,
			googleMapsEmbedUrl: mapsEmbedUrl,
			googleMapsPlaceUrl: mapsUrl,
			googleReviewsUrl: mapsUrl,
			googleRating: 0,
			googleReviewCount: 0,
			openingHours: [
				{ label: 'Monday', opens: '', closes: '', closed: true },
				{ label: 'Tuesday', opens: '', closes: '', closed: true },
				{ label: 'Wednesday', opens: '', closes: '', closed: true },
				{ label: 'Thursday', opens: '', closes: '', closed: true },
				{ label: 'Friday', opens: '', closes: '', closed: true },
				{ label: 'Saturday', opens: '', closes: '', closed: true },
				{ label: 'Sunday', opens: '', closes: '', closed: true }
			],
			serviceAreas: [
				{
					slug: `${toSlug(city)}-${toSlug(region)}${areaSuffix}`,
					name: `${city}, ${region}`,
					summary: `Local service area for ${city}.`
				}
			],
			services: [
				{
					name: 'Primary Service',
					description: 'Describe the core service this business offers.'
				},
				{
					name: 'Secondary Service',
					description: 'Describe another high-demand service.'
				}
			],
			featuredReviews: [],
			faqItems: [
				{
					question: 'Where are you located?',
					answer: `We are located at ${streetAddress}, ${city}, ${region} ${postalCode}.`
				},
				{
					question: 'How can I contact you?',
					answer: `Call ${phone} or email ${email}.`
				}
			],
			events: []
		};
	}

	const locations = Array.from({ length: locationCount }, (_, index) => createLocation(index + 1));

	const locationsPayload = {
		locations
	};
	const storeProfile = locationToStoreProfile(locations[0]);

	await writeFile(
		path.join(repoRoot, 'src', 'data', 'locations.json'),
		`${JSON.stringify(locationsPayload, null, 2)}\n`,
		'utf8'
	);
	await writeFile(
		path.join(repoRoot, 'src', 'data', 'store.json'),
		`${JSON.stringify(storeProfile, null, 2)}\n`,
		'utf8'
	);

	const domain = args.domain || 'example.com';
	const cmsDomain = args['cms-domain'] || `cms.${domain}`;
	const letsencryptEmail = args['letsencrypt-email'] || 'ops@example.com';
	const customerPresetDir = path.join(repoRoot, 'deploy', 'payload', 'customer-presets');
	await mkdir(customerPresetDir, { recursive: true });

	const customerPresetContents = [
		`CMS_DOMAIN=${cmsDomain}`,
		`LETSENCRYPT_EMAIL=${letsencryptEmail}`,
		'POSTGRES_DB=payload',
		'POSTGRES_USER=payload',
		'POSTGRES_PASSWORD=replace_with_strong_db_password',
		'PAYLOAD_SECRET=replace_with_long_random_secret',
		'BACKUP_SCHEDULE=30 3 * * *',
		'BACKUP_KEEP_DAYS=7',
		'BACKUP_KEEP_WEEKS=4',
		'BACKUP_KEEP_MONTHS=6',
		''
	].join('\n');

	const customerPresetPath = path.join(customerPresetDir, `${slug}.env.example`);
	await writeFile(customerPresetPath, customerPresetContents, 'utf8');

	console.log('Client bootstrap complete.');
	console.log(`- Generated ${locationCount} location${locationCount === 1 ? '' : 's'}`);
	console.log(`- Updated src/data/locations.json`);
	console.log(`- Updated src/data/store.json`);
	console.log(`- Created deploy/payload/customer-presets/${slug}.env.example`);
	console.log('Next steps:');
	console.log('1) Review generated data and copy updates into Payload');
	console.log('2) Set frontend env values PAYLOAD_API_URL and PAYLOAD_ADMIN_URL');
	console.log('3) Deploy Astro + Payload stack');
}

await main();
