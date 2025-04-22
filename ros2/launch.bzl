""" Defines launch_ros-like ROS 2 deployment.
"""

load("@com_github_mvukov_rules_ros2//ros2:ament.bzl", "py_launcher")
load("@com_github_mvukov_rules_ros2//ros2:ament.bzl", "ros2_resource")
load("@rules_python//python:defs.bzl", "py_binary")

def _launch_dependency_wrapper_impl(ctx):
    runfiles = ctx.runfiles()

    # Collect runfiles from data and deps
    for dep in ctx.attr.data:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    return DefaultInfo(
        files = depset(),
        runfiles = runfiles
    )

launch_dependency_wrapper = rule(
    implementation = _launch_dependency_wrapper_impl,
    attrs = {
        "deps": attr.label_list(allow_files = True),
        "data": attr.label_list(allow_files = True),
        "idl_deps": attr.label_list(allow_files = True),
    },
)

def ros2_launch(name, ros2_package_name, launch_file, nodes = None, deps = None, data = None, idl_deps = None, **kwargs):
    """ Defines a ROS 2 deployment.

    Args:
        name: A unique target name.
        launch_file: A ros2launch-compatible launch file.
        nodes: A list of ROS 2 nodes for the deployment.
        deps: Additional Python deps that can be used by the launch file.
        data: Additional data that can be used by the launch file.
        idl_deps: Additional IDL deps that are used as runtime plugins.
        **kwargs: https://bazel.build/reference/be/common-definitions#common-attributes-binaries
    """

    ros2_resource(
        name = name + "_launch_resources",
        srcs = native.glob(["launch/**"]),
        package_name = ros2_package_name,
        destination = "launch",
        visibility = ["//visibility:public"],
    )

    nodes = nodes or []
    deps = deps or []

    launch_dependency_wrapper(
        name = name,
        deps = nodes + deps,
        data = (data or []) + [name + "_launch_resources", "@ros2_launch//:frontend_resources"],
        idl_deps = idl_deps,
        visibility = ["//visibility:public"],
    )

    launcher = "{}_launch".format(name)
    launch_script = py_launcher(
        launcher,
        deps = [name],
        template = "@com_github_mvukov_rules_ros2//ros2:launch.py.tpl",
        substitutions = {
            "{launch_file}": "$(rootpath {})".format(launch_file),
        },
        data = [launch_file],
        tags = ["manual"],
    )

    data = data or []
    py_binary(
        name = name + "_run",
        srcs = [launcher],
        data = nodes + [launch_file] + data,
        main = launch_script,
        deps = [
            "@ros2_launch_ros//:ros2launch",
            "@ros2cli",
        ] + deps,
        **kwargs,
    )
