#!/usr/bin/python

import os
import sys

from collections import defaultdict

import xml.dom.minidom
from xml.dom.minidom import Document
from xml.dom.minidom import Element


def parse_instance(instance: Element, pattern_name: str):
    # Dictionary containing list of role names to include for each pattern.
    # Results XML contains methods, not just classes, so we need to filter
    # what we need out.
    participating_roles = {
            'Factory Method': ['Creator'],
            '(Object)Adapter': ['Adaptee', 'Adapter']
            }

    # If there are no participating roles for the pattern, there is no work
    if pattern_name not in participating_roles:
        return set([])

    instance_elements = set([])

    for role in instance.childNodes:
        role: Element

        if role.nodeName != 'role':
            continue

        role_name = role.getAttribute('name')
        role_elem = role.getAttribute('element')

        if role_name in participating_roles[pattern_name]:
            instance_elements.add(role_elem)

    return instance_elements


def parse_patterns(system):
    # Dictionary containing a set of all classes participating in a pattern.
    pattern_elements = defaultdict(set)

    for pattern in system.childNodes:
        pattern: Element

        # There are child nodes with name '#text' in the DOM?? idk o~o
        # Regardless, we want to filter to only pattern children
        if pattern.nodeName != 'pattern':
            continue

        pattern_name = pattern.getAttribute('name')

        print('Parsing instances of', pattern_name)

        for instance in pattern.childNodes:
            instance: Element

            if instance.nodeName != 'instance':
                continue

            instance_elements = parse_instance(instance, pattern_name)
            pattern_elements[pattern_name] = pattern_elements[pattern_name] | instance_elements

    return pattern_elements


def main():
    if len(sys.argv) < 4:
        print('Usage: process_results.py PROJECT INPUT_DIR RESULTS_DIR')
        exit(-1)

    project = sys.argv[1]
    input_dir = sys.argv[2]
    results_dir = sys.argv[3]

    project_dir = os.path.join(input_dir, project)
    project_results_file = os.path.join(results_dir, project + '.xml')

    dom = xml.dom.minidom.parse(project_results_file)
    dom: Document

    system: Element = None
    for child in dom.childNodes:
        child: Element

        if child.nodeName == 'system':
            system = child

    patterns = parse_patterns(system)
    print(patterns)


if __name__ == '__main__':
    main()
