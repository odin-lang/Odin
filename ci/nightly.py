import os
import sys
from zipfile  import ZipFile, ZIP_DEFLATED
from b2sdk.v2 import InMemoryAccountInfo, B2Api
from datetime import datetime, UTC
import json

UPLOAD_FOLDER = "nightly/"

info   = InMemoryAccountInfo()
b2_api = B2Api(info)
application_key_id = os.environ['APPID']
application_key    = os.environ['APPKEY']
bucket_name        = os.environ['BUCKET']
days_to_keep       = os.environ['DAYS_TO_KEEP']

def auth() -> bool:
	try:
		realm = b2_api.account_info.get_realm()
		return True # Already authenticated
	except:
		pass        # Not yet authenticated

	err = b2_api.authorize_account("production", application_key_id, application_key)
	return err is None

def get_bucket():
	if not auth(): sys.exit(1)
	return b2_api.get_bucket_by_name(bucket_name)

def remove_prefix(text: str, prefix: str) -> str:
	return text[text.startswith(prefix) and len(prefix):]

def create_and_upload_artifact_zip(platform: str, artifact: str) -> int:
	now = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)

	source_archive: str
	destination_name = f'odin-{platform}-nightly+{now.strftime("%Y-%m-%d")}'

	if platform.startswith("linux") or platform.startswith("macos"):
		destination_name += ".tar.gz"
		source_archive = artifact
	else:
		destination_name += ".zip"
		source_archive = destination_name

		print(f"Creating archive {destination_name} from {artifact} and uploading to {bucket_name}")
		with ZipFile(source_archive, mode='w', compression=ZIP_DEFLATED, compresslevel=9) as z:
			for root, directory, filenames in os.walk(artifact):
				for file in filenames:
					file_path = os.path.join(root, file)
					zip_path  = os.path.join("dist", os.path.relpath(file_path, artifact))
					z.write(file_path, zip_path)

		if not os.path.exists(source_archive):
			print(f"Error: Newly created ZIP archive {source_archive} not found.")
			return 1

	print("Uploading {} to {}".format(source_archive, UPLOAD_FOLDER + destination_name))
	bucket = get_bucket()
	res = bucket.upload_local_file(
		source_archive,               # Local file to upload
		"nightly/" + destination_name, # B2 destination path
	)
	return 0

def prune_artifacts():
	print(f"Looking for binaries to delete older than {days_to_keep} days")

	bucket = get_bucket()
	for file, _ in bucket.ls(UPLOAD_FOLDER, latest_only=False):
		# Timestamp is in milliseconds
		date  = datetime.fromtimestamp(file.upload_timestamp / 1_000.0).replace(hour=0, minute=0, second=0, microsecond=0)
		now   = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
		delta = now - date

		if delta.days > int(days_to_keep):
			print("Deleting {}".format(file.file_name))
			file.delete()

	return 0

def update_nightly_json():
	print(f"Updating nightly.json with files {days_to_keep} days or newer")

	files_by_date = {}

	bucket = get_bucket()

	for file, _ in bucket.ls(UPLOAD_FOLDER, latest_only=True):
		# Timestamp is in milliseconds
		date = datetime.fromtimestamp(file.upload_timestamp / 1_000.0).replace(hour=0, minute=0, second=0, microsecond=0).strftime('%Y-%m-%d')
		name = remove_prefix(file.file_name, UPLOAD_FOLDER)
		sha1 = file.content_sha1
		size = file.size
		url  = bucket.get_download_url(file.file_name)

		if date not in files_by_date.keys():
			files_by_date[date] = []

		files_by_date[date].append({
			'name':        name,
			'url':         url,
			'sha1':        sha1,
			'sizeInBytes': size,
		})

	now = datetime.now(UTC).isoformat()

	nightly = json.dumps({
		'last_updated' : now,
		'files': files_by_date
	}, sort_keys=True, indent=4, ensure_ascii=False).encode('utf-8')

	res = bucket.upload_bytes(
		nightly,        # JSON bytes
		"nightly.json", # B2 destination path
	)
	return 0

if __name__ == "__main__":
	if len(sys.argv) == 1:
		print("Usage: {} <verb> [arguments]".format(sys.argv[0]))
		print("\tartifact <platform prefix> <artifact path>\n\t\tCreates and uploads a platform artifact zip.")
		print("\tprune\n\t\tDeletes old artifacts from bucket")
		print("\tjson\n\t\tUpdate and upload nightly.json")
		sys.exit(1)
	else:
		command = sys.argv[1].lower()
		if command == "artifact":
			if len(sys.argv) != 4:
				print("Usage: {} artifact <platform prefix> <artifact path>".format(sys.argv[0]))
				print("Error: Expected artifact command to be given platform prefix and artifact path.\n")
				sys.exit(1)

			res = create_and_upload_artifact_zip(sys.argv[2], sys.argv[3])
			sys.exit(res)

		elif command == "prune":
			res = prune_artifacts()
			sys.exit(res)

		elif command == "json":
			res = update_nightly_json()
			sys.exit(res)
