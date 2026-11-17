# Invoked by `sam build` (BuildMethod: makefile) inside the python3.12 build container.
# Layer contents are extracted to /opt, so packages land in /opt/python and NLTK data in /opt/nltk_data.
build-LayerSumy:
	python3 -m pip install -r requirements.txt -t "$(ARTIFACTS_DIR)/python"
	PYTHONPATH="$(ARTIFACTS_DIR)/python" python3 -m nltk.downloader -d "$(ARTIFACTS_DIR)/nltk_data" punkt_tab
