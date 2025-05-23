#
# Copyright (c) 2018, 2024 Scott O'Connor
#
# Par rating, slope and par for each course.
#
# Par and handicap hole for each hole.
#
%c = (
    # South Front
    SF => {
        name => "South Front",
        #
        # Par and handicap hole for each hole.
        #
        1 => [ 4, 7 ],
        2 => [ 4, 1 ],
        3 => [ 3, 9 ],
        4 => [ 4, 5 ],
        5 => [ 4, 6 ],
        6 => [ 4, 8 ],
        7 => [ 5, 3 ],
        8 => [ 5, 4 ],
        9 => [ 3, 2 ],
        #
        # USGA
        course_rating => 35.0, slope => 119, par => 36,
    },
    # South Back
    SB => {
        name => "South Back",
        #
        # Par and handicap hole for each hole.
        #
        1 => [ 4, 8 ],
        2 => [ 3, 9 ],
        3 => [ 4, 5 ],
        4 => [ 4, 7 ],
        5 => [ 5, 2 ],
        6 => [ 3, 6 ],
        7 => [ 4, 1 ],
        8 => [ 3, 4 ],
        9 => [ 5, 3 ],
        #
        # USGA
        course_rating => 34.2, slope => 129, par => 35,
    },
    # North Front
    NF => {
        name => "North Front",
        #
        # Par and handicap hole for each hole.
        #
        1 => [ 5, 3 ],
        2 => [ 4, 6 ],
        3 => [ 4, 7 ],
        4 => [ 4, 2 ],
        5 => [ 5, 4 ],
        6 => [ 3, 5 ],
        7 => [ 4, 8 ],
        8 => [ 3, 9 ],
        9 => [ 4, 1 ],
        #
        # USGA
        course_rating => 35.6, slope => 124, par => 36,
    },
    # North Back
    NB => {
        name => "North Back",
        #
        # Par and handicap hole for each hole.
        #
        1 => [ 4, 2 ],
        2 => [ 4, 3 ],
        3 => [ 5, 9 ],
        4 => [ 3, 8 ],
        5 => [ 4, 7 ],
        6 => [ 4, 4 ],
        7 => [ 3, 6 ],
        8 => [ 4, 5 ],
        9 => [ 5, 1 ],
        #
        # USGA
        course_rating => 35.1, slope => 130, par => 36,
    },
);
