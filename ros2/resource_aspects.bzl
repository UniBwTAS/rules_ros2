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
""" ROS 2 resource providers and aspects.
"""

Ros2ResourceInfo = provider(
    "Information about ROS2 resources that should be installed",
    fields = [
        "resources",  # Dictionary mapping from source files to destination paths
        "package_name",  # The ROS2 package name
    ],
)

Ros2ResourceCollectorAspectInfo = provider(
    "Provides info about collected ROS2 resources.",
    fields = [
        "resources",
    ],
)

_ROS2_COLLECTOR_ATTR_ASPECTS = ["data", "deps"]

def _get_list_attr(rule_attr, attr_name):
    if not hasattr(rule_attr, attr_name):
        return []
    candidate = getattr(rule_attr, attr_name)
    if type(candidate) != "list":
        fail("Expected a list for attribute `{}`!".format(attr_name))
    return candidate

def _collect_deps(rule_attr, attr_name, provider_info):
    return [
        dep
        for dep in _get_list_attr(rule_attr, attr_name)
        if type(dep) == "Target" and provider_info in dep
    ]

def _get_transitive_items(ctx, aspect_name, item_name):
    transitive_items = []
    for attr_name in _ROS2_COLLECTOR_ATTR_ASPECTS:
        for dep in _collect_deps(ctx.rule.attr, attr_name, aspect_name):
            transitive_items.append(getattr(dep[aspect_name], item_name))
    return transitive_items

def _ros2_resource_collector_aspect_impl(target, ctx):
    direct_resources = []
    if Ros2ResourceInfo in target:
        direct_resources.append(target[Ros2ResourceInfo])

    transitive_resources = _get_transitive_items(
        ctx,
        Ros2ResourceCollectorAspectInfo,
        "resources",
    )

    return [
        Ros2ResourceCollectorAspectInfo(
            resources = depset(
                direct = direct_resources,
                transitive = transitive_resources,
            ),
        ),
    ]

ros2_resource_collector_aspect = aspect(
    implementation = _ros2_resource_collector_aspect_impl,
    attr_aspects = _ROS2_COLLECTOR_ATTR_ASPECTS,
    provides = [Ros2ResourceCollectorAspectInfo],
)