#!/usr/bin/python

import os
import sys

from collections import defaultdict

import xml.dom.minidom
from xml.dom.minidom import Document
from xml.dom.minidom import Element


def parse_instance_factory(instance):
    print('PARSING fac')
    return set([])


def parse_instance_singleton(instance):
    print('PARSING Singleton')
    return set([])


def parse_patterns(system):
    # Dictionary containing a set of all classes participating in a pattern.
    patterns = defaultdict(set)

    # Dictionary of instance parsers, where the key is the pattern name as in
    # the results XML. Each parser returns a set of classes from that instance.
    instance_handlers = {
            'Factory Method': parse_instance_factory,
            'Singleton': parse_instance_singleton
            }

    for pattern in system.childNodes:
        pattern: Element

        # There are child nodes with name '#text' in the DOM?? idk o~o
        # Regardless, we want to filter to only pattern children
        if pattern.nodeName != 'pattern':
            continue

        pattern_name = pattern.getAttribute('name')

        if pattern_name not in instance_handlers:
            print('Handler not found for', pattern_name)
            continue

        print('Parsing instances of', pattern_name)

        # Each of the patterns have children containing instances. Each pattern
        # has its own parser to parse one of these instances. Finding all
        # instances here reduces redundancy compared to having a handler for
        # each pattern.
        instance_parser = instance_handlers[pattern_name]

        for instance in pattern.childNodes:
            instance: Element

            if instance.nodeName != 'instance':
                continue

            instance_classes = instance_parser(instance)
            patterns[pattern_name] = patterns[pattern_name] | instance_classes


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


if __name__ == '__main__':
    main()
