vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# Pinned to the ptx_frontend commit this overlay was last validated against.
# Bump REF together with SHA512; port-version must increase on every bump.
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO endingly/ptx_frontend
    REF 0025ee50eae6284750c5114a36ec155d4ede6951
    SHA512 030e43623650b5a29e1920fda1e6d9f7c65ac4204b233522185baad5433a2fb0571b6ed16af8ff609e5beda21e2eaded6aca6e26ab346d050fdb7525cab791ea
    HEAD_REF main
)

# The requirements file's editable path is relative to the source checkout;
# vcpkg installs it from its buildtree instead.
vcpkg_replace_string(
    "${SOURCE_PATH}/requirements.txt"
    "-e ./python"
    "-e ${SOURCE_PATH}/python"
)

x_vcpkg_get_python_packages(
    PYTHON_VERSION 3
    OUT_PYTHON_VAR PYTHON3
    REQUIREMENTS_FILE "${SOURCE_PATH}/requirements.txt"
)

vcpkg_find_acquire_program(FLEX)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DPTX_USE_CCACHE=OFF
        "-DFLEX_EXECUTABLE=${FLEX}"
        "-DPython3_EXECUTABLE=${PYTHON3}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME ptx_frontend
    CONFIG_PATH lib/cmake/ptx_frontend
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
