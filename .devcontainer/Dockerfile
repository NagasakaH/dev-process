FROM nagasakah/dev-process:base

RUN pip install jsonschema pyyaml \
    && echo '--- Tool versions ---' \
    && dotnet --version \
    && node --version \
    && python3 --version \
    && uv --version \
    && yq --version \
    && aws --version \
    && terraform --version | head -1 \
    && gh --version | head -1
