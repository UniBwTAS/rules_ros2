# Copyright 2022 Milan Vukov
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ros2NodeCollectorAspectInfo = provider(
    "Provides info about collected ROS nodes.",
    fields = ["node_infos"],
)

def _ros2_node_collector_aspect_impl(target, ctx):
    collected = []

    if hasattr(ctx.rule.attr, "tags") and "ros2_node" in ctx.rule.attr.tags:
        # get package name from the target
        ros_package_name = target.label.package
        if ros_package_name:
            ros_package_name = ros_package_name.split("/")[-1]
        elif "+ros2_" in ctx.label.repo_name:
            ros_package_name = ctx.label.repo_name.split("+ros2_")[-1]
        else:
            ros_package_name = ctx.label.name.split("+")[-1]

        # get node name from the target
        ros_node_name = ctx.label.name.split("/")[-1]
        if ros_node_name.endswith("_impl"):
            ros_node_name = ros_node_name[:-len("_impl")]

        # get executable File object from the target
        executable_file = target[DefaultInfo].files.to_list()[0]

        node_info = struct(
            package_name = ros_package_name,
            node_name = ros_node_name,
            executable = executable_file,
        )
        collected.append(node_info)

    # Collect transitive info from dependencies
    transitive = []
    if hasattr(ctx.rule.attr, "deps"):
        transitive += [dep[Ros2NodeCollectorAspectInfo].node_infos
            for dep in ctx.rule.attr.deps
            if Ros2NodeCollectorAspectInfo in dep]
    if hasattr(ctx.rule.attr, "data"):
        transitive += [dep[Ros2NodeCollectorAspectInfo].node_infos
            for dep in ctx.rule.attr.data
            if Ros2NodeCollectorAspectInfo in dep]

    return [
        Ros2NodeCollectorAspectInfo(
            node_infos = depset(
                direct = collected,
                transitive = transitive,
            ),
        ),
    ]

ros2_node_collector_aspect = aspect(
    implementation = _ros2_node_collector_aspect_impl,
    attr_aspects = ["deps", "data"],
    provides = [Ros2NodeCollectorAspectInfo],
)