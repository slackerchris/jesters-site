import storeData from '../data/store.json';
import locationsData from '../data/locations.json';

export interface OpeningHour {
	label: string;
	opens: string;
	closes: string;
	closed: boolean;
}

export interface ServiceArea {
	slug: string;
	name: string;
	summary: string;
}

export interface ServiceItem {
	name: string;
	description: string;
}

export interface ReviewSnippet {
	author: string;
	rating: number;
	text: string;
	source: string;
}

export interface FaqItem {
	question: string;
	answer: string;
}

export interface EventItem {
	title: string;
	date: string;
	time: string;
	location: string;
	description: string;
	facebookEventUrl: string;
}

export interface StoreProfile {
	name: string;
	tagline: string;
	websiteUrl: string;
	phone: string;
	email: string;
	priceRange: string;
	address: {
		streetAddress: string;
		city: string;
		region: string;
		postalCode: string;
		countryCode: string;
	};
	facebookPageUrl: string;
	googleMapsEmbedUrl: string;
	googleMapsPlaceUrl: string;
	googleReviewsUrl: string;
	googleRating: number;
	googleReviewCount: number;
	openingHours: OpeningHour[];
	serviceAreas: ServiceArea[];
	services: ServiceItem[];
	featuredReviews: ReviewSnippet[];
	faqItems: FaqItem[];
	events: EventItem[];
}

export interface StoreLocation extends StoreProfile {
	slug: string;
	status: string;
	landingSummary: string;
}

type LocationsDataShape = StoreLocation[] | { locations: StoreLocation[] };
const parsedLocationsData = locationsData as LocationsDataShape;
const localStoreLocations = Array.isArray(parsedLocationsData)
	? parsedLocationsData
	: parsedLocationsData.locations;

interface PayloadListResponse {
	docs?: unknown[];
}

function isStoreLocationCandidate(value: unknown): value is StoreLocation {
	if (!value || typeof value !== 'object') {
		return false;
	}

	const candidate = value as Partial<StoreLocation>;
	return (
		typeof candidate.slug === 'string' &&
		typeof candidate.name === 'string' &&
		Array.isArray(candidate.openingHours) &&
		Array.isArray(candidate.services) &&
		Array.isArray(candidate.serviceAreas)
	);
}

function toStoreLocations(values: unknown[]): StoreLocation[] {
	return values.filter(isStoreLocationCandidate);
}

async function loadStoreLocations(): Promise<StoreLocation[]> {
	const payloadApiUrl = import.meta.env.PAYLOAD_API_URL as string | undefined;

	if (!payloadApiUrl) {
		return localStoreLocations;
	}

	const baseUrl = payloadApiUrl.replace(/\/$/, '');

	try {
		const response = await fetch(`${baseUrl}/api/locations?limit=100&depth=2`);
		if (!response.ok) {
			return localStoreLocations;
		}

		const payloadData = (await response.json()) as PayloadListResponse;
		const docs = Array.isArray(payloadData.docs) ? payloadData.docs : [];
		const parsed = toStoreLocations(docs);

		if (parsed.length === 0) {
			return localStoreLocations;
		}

		return parsed;
	} catch {
		return localStoreLocations;
	}
}

export const storeLocations = await loadStoreLocations();

export function getStoreLocationBySlug(slug: string): StoreLocation | undefined {
	return storeLocations.find((location) => location.slug === slug);
}

export function getFullStreetAddress(profile: StoreProfile): string {
	return `${profile.address.streetAddress}, ${profile.address.city}`;
}

export const storeProfile = (storeLocations[0] ?? (storeData as StoreProfile)) as StoreProfile;
export const fullStreetAddress = getFullStreetAddress(storeProfile);
