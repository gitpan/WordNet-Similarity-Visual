#!/usr/bin/perl -w

# this will start the visual interface

use WordNet::Similarity::Visual;

$gui = WordNet::Similarity::Visual->new;

$gui->initialize;
