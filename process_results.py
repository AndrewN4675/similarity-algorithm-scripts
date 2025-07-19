#!/usr/bin/python

import os
import sys

from collections import defaultdict

import pandas
import xml.dom.minidom
from xml.dom.minidom import Document
from xml.dom.minidom import Element


def parse_instance(instance: Element, pattern_name: str):
    # Dictionary containing list of role names to include for each pattern.
    # Results XML contains methods, not just classes, so we need to filter
    # what we need out.
    participating_roles = {
            'Factory Method': ['Creator'],
            'Singleton': ['Singleton'],
            '(Object)Adapter': ['Adapter', 'Adaptee'],
            'Composite': ['Component', 'Composite'],
            'State': ['Context', 'State'],
            'Bridge': ['Abstraction', 'Implementor'],
            'Template Method': ['AbstractClass'],
            'Decorator': ['Component', 'Decorator'],
            'Observer': ['Observer', 'Subject'],
            'Strategy': ['Strategy', 'Context'],
            'Visitor': ['Visitor', 'ConcreteElement'],
            'Proxy': ['RealSubject', 'Proxy'],
            'Proxy2': ['RealSubject', 'Proxy'],
            'Chain of Responsibility': ['Handler'],
            'Command': ['ConcreteCommand', 'Receiver'],
            'Prototype': ['Client', 'Prototype'],
            }

    # If there are no participating roles for the pattern, there is no work
    if pattern_name not in participating_roles:
        print('No used roles for pattern', pattern_name)
        return set([])

    instance_elements = set([])

    for role in instance.childNodes:
        role: Element

        if role.nodeName != 'role':
            continue

        role_name = role.getAttribute('name')
        role_elem = role.getAttribute('element')

        # Remove the template(?) part from class name
        class_name = role_elem.partition('$')[0]

        if role_name in participating_roles[pattern_name]:
            instance_elements.add(class_name)

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

        for instance in pattern.childNodes:
            instance: Element

            if instance.nodeName != 'instance':
                continue

            instance_elements = parse_instance(instance, pattern_name)
            pattern_elements[pattern_name] = pattern_elements[pattern_name] | instance_elements

    return pattern_elements


# Finds all classes inside project directory
def find_classes(project_dir):
    classes = set([])

    for root, dirs, files in os.walk(project_dir):
        for file in files:
            base, ext = os.path.splitext(file)

            package_as_path = os.path.relpath(root, project_dir)
            package = package_as_path.replace('/', '.')

            # Remove the template(?) part of different class instances
            class_name = base.partition('$')[0]
            class_fqn = package + '.' + class_name

            if ext == '.class':
                classes.add(class_fqn)

    return classes


def main():
    if len(sys.argv) < 4:
        print('Usage: process_results.py PROJECT INPUT_DIR RESULTS_DIR')
        exit(-1)

    project = sys.argv[1]
    input_dir = sys.argv[2]
    results_dir = sys.argv[3]

    project_dir = os.path.join(input_dir, project)
    project_results_file = os.path.join(results_dir, project + '.xml')
    project_out_instances_file = os.path.join(results_dir, project + '.csv')

    empty_projects_file = os.path.join(results_dir, 'empty')

    dom = xml.dom.minidom.parse(project_results_file)
    dom: Document

    # "system" is the root(?) element of the XML file. Dunno if that's the
    # right terminology, but ehhh o~o
    system: Element = None
    for child in dom.childNodes:
        child: Element

        if child.nodeName == 'system':
            system = child

    # Dictionary of classes participating in each pattern
    pattern_elements = parse_patterns(system)
    # Set of all classes in the project
    all_elements = find_classes(project_dir)

    # If the project empty, pandas complains so we handle that case here
    if len(all_elements) == 0:
        print('No classes in project!')

        # Creating an empty results file so we have some output
        open(project_out_instances_file, 'w').close()

        # Also add the project to a logfile of empty projects
        with open(empty_projects_file, 'a') as file:
            file.write(project + '\n')

        return

    # First we need to create a dataframe that contains classes with their pattern
    instances_df = pandas.DataFrame(columns=['instance', 'pattern'])

    for pattern in pattern_elements.keys():
        # Pad with pattern name to fit pandas expected format
        padded_records = [
                {'pattern': pattern, 'instance': e}
                for e in pattern_elements[pattern]
                ]

        new_instances_df = pandas.DataFrame.from_records(padded_records)
        instances_df = pandas.concat([instances_df, new_instances_df])

    # Using class name as index so we can perform difference on it
    instances_df.set_index('instance', inplace=True)

    # Creating a dataframe containing "None" for all classes that we can use to
    # fill in classes without patterns
    padded_records = [
            {'pattern': 'None', 'instance': e}
            for e in all_elements
            ]

    all_instances_df = pandas.DataFrame.from_records(padded_records)
    all_instances_df.set_index('instance', inplace=True)

    # The full dataset contains classes with patterns and without,
    # create it using difference
    missing_index = all_instances_df.index.difference(instances_df.index)
    instances_df = pandas.concat([instances_df, all_instances_df.loc[missing_index]])

    instances_df.to_csv(project_out_instances_file)


if __name__ == '__main__':
    main()
