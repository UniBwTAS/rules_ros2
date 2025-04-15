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

Ros2BinCollectorAspectInfo = provider(
    "Provides info about collected ROS bins that should be available at runtime (e.g. in launch files).",
    fields = ["bin_infos"],
)

def _ros2_bin_collector_aspect_impl(target, ctx):
    collected = []

    if hasattr(ctx.rule.attr, "tags") and "ros2_bin" in ctx.rule.attr.tags:
        # get bin name from the target
        ros2_bin_name = ctx.label.name.split("/")[-1]
        if ros2_bin_name.endswith("_ros2_bin"):
            ros2_bin_name = ros2_bin_name[:-len("_ros2_bin")]

        # get executable File object from the target
        executable = target[DefaultInfo].files.to_list()[0]

        bin_info = struct(
            ros2_bin_name = ros2_bin_name,
            executable = executable,
        )
        collected.append(bin_info)

    # Collect transitive info from dependencies
    transitive = [
        dep[Ros2BinCollectorAspectInfo].bin_infos
        for dep in ctx.rule.attr.deps
        if Ros2BinCollectorAspectInfo in dep
    ]

    return [
        Ros2BinCollectorAspectInfo(
            bin_infos = depset(
                direct = collected,
                transitive = transitive,
            ),
        ),
    ]

ros2_bin_collector_aspect = aspect(
    implementation = _ros2_bin_collector_aspect_impl,
    attr_aspects = ["deps"],
    provides = [Ros2BinCollectorAspectInfo],
)