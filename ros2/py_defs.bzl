""" Defines commonly used Python macros.
"""

load("@com_github_mvukov_rules_ros2//ros2:ament.bzl", "sh_launcher", "split_kwargs")
load("@com_github_mvukov_rules_ros2//third_party:symlink.bzl", "symlink")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")

def _ros2_py_exec(target, name, ros2_package_name, srcs, main, set_up_ament, **kwargs):
    is_test = target == py_test
    set_up_launcher = is_test or set_up_ament
    if set_up_launcher == False:
        tags = kwargs.pop("tags", []) + ["ros2_node"]
        target(name = name, srcs = srcs, main = main, tags = tags, **kwargs)
        return

    launcher_target_kwargs, binary_kwargs = split_kwargs(**kwargs)
    tags = launcher_target_kwargs.pop("tags", []) + ["manual", "ros2_node"]
    target(name = name, srcs = srcs, main = main, tags = tags, **binary_kwargs)

    launcher = "{}_launch".format(name)
    ament_setup_deps = [name] if set_up_ament else None
    sh_launcher(
        launcher,
        ament_setup_deps = ament_setup_deps,
        template = "@com_github_mvukov_rules_ros2//ros2:launch.sh.tpl",
        substitutions = {
            "{entry_point}": "$(rootpath {})".format(name),
        },
        tags = ["manual"],
        data = [name],
        testonly = is_test,
    )

    sh_target = native.sh_test if is_test else native.sh_binary
    sh_target(
        name = name + "_run",
        srcs = [launcher],
        data = [name],
        **launcher_target_kwargs
    )

def ros2_py_binary(name, ros2_package_name, srcs, main, set_up_ament = False, **kwargs):
    """ Defines a ROS 2 Python binary.

    Args:
        name: A unique target name.
        srcs: List of source files.
        main: Source file to use as entrypoint.
        set_up_ament: If true, sets up ament file tree for the binary target.
        **kwargs: https://bazel.build/reference/be/common-definitions#common-attributes-binaries
    """
    _ros2_py_exec(py_binary, name, ros2_package_name, srcs, main, set_up_ament, **kwargs)

def ros2_py_test(name, ros2_package_name, srcs, main, set_up_ament = True, **kwargs):
    """ Defines a ROS 2 Python test.

    Defaults ROS_HOME and ROS_LOG_DIR to $TEST_UNDECLARED_OUTPUTS_DIR (if set,
    otherwise to $TEST_TMPDIR, see https://bazel.build/reference/test-encyclopedia#initial-conditions)

    Please make sure that --sandbox_default_allow_network=false is set in .bazelrc.
    This ensures proper network isolation.

    Args:
        name: A unique target name.
        srcs: List of source files.
        main: Source file to use as entrypoint.
        set_up_ament: If true, sets up ament file tree for the test target.
        **kwargs: https://bazel.build/reference/be/common-definitions#common-attributes-tests
    """
    _ros2_py_exec(py_test, name, ros2_package_name, srcs, main, set_up_ament, **kwargs)
