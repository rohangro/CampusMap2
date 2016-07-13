#!/usr/bin/env python
#
# Copyright 2010 David Lindquist and Michael Kelly
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from google.appengine.ext import webapp
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp import util

import cgi
import logging
import math
import os
import urllib

import campusmap

class ViewHandler(webapp.RequestHandler):
    def get(self):
        self.display()

    def post(self):
        self.display()

    def display(self):
        # this is the core map logic
        m = campusmap.Map()

        src = self.request.get("from")
        dst = self.request.get("to")

        src_locs = m.findLocation(src)
        dst_locs = m.findLocation(dst)

        template_values = {
            'html_dir': m.html_base,
            'css_dir': m.html_base + '/css',
            'img_dir': m.html_base + '/img',
            'js_dir': m.html_base + '/js',
            'grid_dir': m.html_base + '/tiles',
            'paths_dir': '/p',

            'self': '/map',

            'size': self.request.get("size") or m.default_size,
            'mpm': self.request.get("mpm") or m.default_mpm,

            'src_found': False,
            'dst_found': False,
            'path_found': False,

            'txt_src': src,
            'txt_dst': dst,

            # These get overridden if we find a path.
            'xoff': m.default_xoff,
            'yoff': m.default_yoff,

            'width': m.viewport_w,
            'height': m.viewport_h,
            'scale': m.default_scale,
            # TODO: should be totally deprecated
            'map_name': 'visitor',
        
            'location_opt': m.locations_menu,
        }

        # Number of locations displayed. Could be 0 (default), 1 (just one
        # location, or a disambiguation page for one of the searched
        # locations), or 2 (full path).
        location_count = 0

        if len(src_locs) == 0 and src.strip():
            if m.isKeyword(src):
                template_values['src_help'] = '<b>%s is not valid.</b>' % cgi.escape(src)
            else:
                template_values['src_help'] = '<b>Start, "%s" could not be found.</b>' % cgi.escape(src)
        elif len(src_locs) == 1:
            template_values['src_found'] = True
            template_values['txt_src'] = src_locs[0]['name']
            template_values['txt_src_official'] = src_locs[0]['name']
            template_values['src_name'] = src_locs[0]['name']
            template_values['src_x'] = src_locs[0]['x']
            template_values['src_y'] = src_locs[0]['y']
            location_count += 1
        elif len(src_locs) > 1:
            help_html = 'Closest matches for <b>%s</b>: <ol>' % cgi.escape(src)

            map_params = {}
            for arg in self.request.arguments():
                map_params[arg] = self.request.get(arg)

            for loc in src_locs:
                map_params['from'] = loc['name']
                help_html += '<li><a href="/map?' + urllib.urlencode(map_params) + '">' 
                help_html += loc['name'] 
                help_html += '</a></li>'

            help_html += '</ol>'
            template_values['src_help'] = help_html

        if len(dst_locs) == 0 and dst.strip():
            if m.isKeyword(dst):
                template_values['dst_help'] = '<b>%s is not valid.</b>' % cgi.escape(dst)
            else:
                template_values['dst_help'] = '<b>Destination, "%s" could not be found.</b>' % cgi.escape(dst)
        elif len(dst_locs) == 1:
            # Check for src == dst
            if len(src_locs) == 1 and src_locs[0]['id'] == dst_locs[0]['id']:
                template_values['dst_found'] = False
                template_values['txt_error'] = ("Source and destination are the"
                        " same! That's easy.")
            else:
                template_values['dst_found'] = True
                template_values['txt_dst'] = dst_locs[0]['name']
                template_values['txt_dst_official'] = dst_locs[0]['name']
                template_values['dst_name'] = dst_locs[0]['name']
                template_values['dst_x'] = dst_locs[0]['x']
                template_values['dst_y'] = dst_locs[0]['y']
                location_count += 1
        elif len(dst_locs) > 1:
            help_html = 'Closest matches for <b>%s</b>: <ol>' % cgi.escape(dst)

            map_params = {}
            for arg in self.request.arguments():
                map_params[arg] = self.request.get(arg)

            for loc in dst_locs:
                map_params['to'] = loc['name']
                distance = None
                if len(src_locs) == 1:
                    path_info = campusmap.PathInfo.fromSrcDst(src_locs[0]['id'], loc['id'])
                    if path_info:
                        distance = float(path_info.dist)/m.pixels_per_mile
                help_html += '<li><a href="/map?' + urllib.urlencode(map_params) + '">'
                help_html += loc['name']
                help_html += '</a>' 
                if distance:
                    help_html += ' (%.02f mi)' % distance
                help_html += '</li>'

            help_html += '</ol>'
            template_values['dst_help'] = help_html

        logging.info('locaton_count = %s', location_count)
        path_info = None
        if location_count == 2:
            path_info = campusmap.PathInfo.fromSrcDst(src_locs[0]['id'], dst_locs[0]['id'])
            if path_info:
                if path_info.dist > 0:
                    logging.info("Got PathInfo: %s", path_info)
                    template_values['path_found'] = True
                    template_values['path_x'] = path_info.x
                    template_values['path_y'] = path_info.y
                    template_values['path_w'] = path_info.w
                    template_values['path_h'] = path_info.h
                    template_values['path_src'] = src_locs[0]['id']
                    template_values['path_dst'] = dst_locs[0]['id']
                    template_values['scale'] = m.pickScale(path_info)
                    template_values['xoff'], template_values['yoff'] = m.pickOffsets(None, None, path_info)

                    distance = float(path_info.dist)/m.pixels_per_mile

                    # Display values
                    template_values['distance'] = "%.02f" % distance
                    template_values['path_dist'] = distance

                    try:
                        mpm = int(self.request.get("mpm"))
                    except ValueError:
                        mpm = m.default_mpm
                    template_values['mpm'] = mpm

                    time = distance * mpm
                    minutes = math.floor(time)
                    seconds = round((time - minutes)*60)
                    template_values['time'] = "%d:%02d" % (minutes, seconds)
                else:
                    # This happens when one endpoint isn't properly connected.
                    # It's an indication that our underlying path data is
                    # dodgy, but not an error to us.
                    logging.warning("IDs: %s %s aren't connected.",
                            src_locs[0]['id'], dst_locs[0]['id'])
                    template_values['path_found'] = False
                    template_values['txt_error'] = (
                            'No known path between these locations.')
            else:
                # This is a genuine error -- we should have PathInfos between all locations.
                logging.error("Couldn't get PathInfo for IDs: %s %s", src_locs[0]['id'], dst_locs[0]['id'])
                template_values['txt_error'] = "Internal error: couldn't retrieve path between locations!"
                template_values['scale'] = m.default_scale
        elif location_count == 1:
                template_values['scale'] = m.default_single_loc_scale

                if template_values['src_found']:
                    template_values['xoff'], template_values['yoff'] = m.pickOffsets(src_locs[0], None, None)
                elif template_values['dst_found']:
                    template_values['xoff'], template_values['yoff'] = m.pickOffsets(None, dst_locs[0], None)
            


        path = os.path.join(os.path.dirname(__file__), m.main_tmpl)
        self.response.out.write(template.render(path, template_values))

