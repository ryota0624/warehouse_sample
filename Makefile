GCP_PROJECT = ""

local_infra:
	firebase emulators:start --only firestore,functions,pubsub --project ${GCP_PROJECT}