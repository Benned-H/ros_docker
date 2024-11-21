# ros_docker

Scripts and config files for creating Dockerized ROS environments

## Using the Tools

**ROS Dependency Scraping** - To scrape all catkin/ROS dependencies from a given `src` directory, run the following commands from the root of this repository:

```bash
pip install .
scrape-ros-deps <path-to-src-directory>
```

The list of package dependencies will be output to the parent folder of the provided `src` directory (i.e., typically the root directory of the catkin workspace).
