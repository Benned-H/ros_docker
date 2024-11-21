"""Scrape the workspace's ROS dependencies so they can be installed by Docker."""

from __future__ import annotations

import sys
from argparse import ArgumentParser
from pathlib import Path

from defusedxml import ElementTree


def find_dependencies(package_xml_path: Path) -> list[str]:
    """Find the dependencies specified in the given package manifest (package.xml).

    :param package_xml_path: Path to the package.xml file for a catkin package
    :returns: List of all catkin package dependencies specified by the package.xml
    """
    tree = ElementTree.parse(package_xml_path)
    root = tree.getroot()

    # List the XML tag names used to specify types of catkin dependencies (in ROS 1)
    depend_tag_names = [
        "depend",
        "build_depend",
        "build_export_depend",
        "exec_depend",
        "test_depend",
        "buildtool_depend",
        "doc_depend",
    ]

    depend_xpaths = [(".//" + tag) for tag in depend_tag_names]  # XPath syntax

    # Find text from the root's descendant XML elements with the relevant tag names
    return [dep.text for xpath in depend_xpaths for dep in root.findall(xpath)]


def main() -> None:
    """Scrape the ROS dependencies of all packages in the catkin workspace."""
    parser = ArgumentParser()
    parser.add_argument(
        "src_path",
        type=Path,
        help="Path to the src/ directory of the catkin workspace",
    )
    args = parser.parse_args()

    src_path: Path = args.src_path

    assert src_path.is_dir(), f"Path '{src_path}' is not a valid directory."
    assert src_path.name == "src", f"The path '{src_path}' is not named 'src'."

    print(f"Searching path '{src_path}' for catkin package dependencies...")

    combined_deps: set[str] = set()

    # Recursively find all package.xml files in the src folder
    for package_xml in src_path.rglob("package.xml"):
        found_deps = find_dependencies(package_xml)
        print(f"{package_xml} included dependencies:\n{found_deps}")
        combined_deps.update(found_deps)

    sorted_deps = sorted(combined_deps)

    if not sorted_deps:
        print(f"Found no catkin dependencies under '{src_path}'.")
        sys.exit(0)

    print(f"Found the dependencies: {"\n".join(sorted_deps)}")

    # Output the dependencies into a file in the workspace's top directory
    output_path = src_path.parent / "catkin_package_deps.txt"
    with output_path.open("w") as deps_file:
        for dep in sorted_deps:
            deps_file.write(f"{dep}\n")

    print(f"Output filepath: {output_path}")


if __name__ == "__main__":
    main()
