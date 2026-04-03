import storeData from '../data/store.json';

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

export const storeProfile = storeData as StoreProfile;
export const fullStreetAddress = `${storeProfile.address.streetAddress}, ${storeProfile.address.city}`;
