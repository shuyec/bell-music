from ytmusicapi import YTMusic
from flask import Flask, make_response, request
from flask_restful import Api, Resource, reqparse, abort
# import youtube_dl
import yt_dlp
import os

app = Flask(__name__)
api = Api(app)
app.config['JSON_SORT_KEYS'] = False


# YTMusicApi setup
if os.path.exists('lib/python/headers_auth.json'):
    ytmusic = YTMusic('lib/python/headers_auth.json')
else:
    ytmusic = YTMusic()

# FLASK RESTFUL API
search_post_args = reqparse.RequestParser()
search_post_args.add_argument("search", type=str)

media_post_args = reqparse.RequestParser()
media_post_args.add_argument("videoId", type=str)
media_post_args.add_argument("rating", type=str)
media_post_args.add_argument("lyrics", type=bool)

album_post_args = reqparse.RequestParser()
album_post_args.add_argument("browseId", type=str)
album_post_args.add_argument("rating", type=str)

artist_post_args = reqparse.RequestParser()
artist_post_args.add_argument("browseId", type=str)
artist_post_args.add_argument("channelId", type=str)

class Search(Resource):
    def post(self):
        type = request.args.get("type", type=str)
        search = search_post_args.parse_args()["search"]
        print(type)
        if search == None:
            abort(404, message="Search string not found")

        if type == None:
            search = ytmusic.search(query=search)
        elif type == "songs":
            search = ytmusic.search(query=search, filter="songs")
        elif type == "albums":
            search = ytmusic.search(query=search, filter="albums")
        elif type == "artists":
            search = ytmusic.search(query=search, filter="artists")
        elif type == "community-playlists":
            search = ytmusic.search(query=search, filter="community_playlists")
        elif type == "featured-playlists":
            search = ytmusic.search(query=search, filter="featured_playlists")
        elif type == "videos":
            search = ytmusic.search(query=search, filter="videos")
        else:
            abort(400, message="Invalid search")
        return search, 201

# TODO: pagination
class Media(Resource):
    def post(self):
        arguments = media_post_args.parse_args()
        video_id = arguments["videoId"]
        rating = arguments["rating"]
        lyrics = arguments["lyrics"]
        if video_id == None:
            abort(400, message="Video Id needed")
        if lyrics:
            watch_playlist = ytmusic.get_watch_playlist(video_id)
            response = watch_playlist["tracks"][0]
            lyrics = ytmusic.get_lyrics(watch_playlist["lyrics"])
            response.update(lyrics)
        elif rating == None:
            media = ytmusic.get_song(video_id)
            if media['playabilityStatus']['status'] == 'ERROR':
                abort(404, message="This video does not exist")
            video_url = "https://www.youtube.com/watch?v=" + video_id
            ydl_opts = {
                'format': 'bestaudio',
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(
                    video_url, download=False)
            audio_url = info['url']
            media_details = media['videoDetails'] 
            data = {
                "videoId": media_details["videoId"],
                "title": media_details["title"],
                "author": media_details["author"],
                "thumbnail": media_details["thumbnail"]["thumbnails"][len(media_details["thumbnail"]["thumbnails"])-1]["url"]
            }
            data.update({"audioUrl": audio_url})
            response = make_response(data, 200)
        elif rating == "LIKE" or rating == "DISLIKE" or rating == "INDIFFERENT":
            response = ytmusic.rate_song(video_id, rating)
        else:
            abort(400, message="Rate value invalid")
        return response
    
class Album(Resource):
    def post(self):
        arguments = album_post_args.parse_args()
        browse_id = arguments["browseId"]
        rating = arguments["rating"]
        if browse_id == None:
            abort(400, message="Browse Id needed")
        if rating == None:
            album = ytmusic.get_album(browse_id)
            response = make_response(album, 200)
        elif rating == "LIKE" or rating == "DISLIKE" or rating == "INDIFFERENT":
            response = ytmusic.rate_playlist(browse_id, rating)
        else:
            abort(400, message="Rate value invalid")
        return response

class Playlist(Resource):
    def post(self):
        arguments = album_post_args.parse_args()
        browse_id = arguments["browseId"]
        rating = arguments["rating"]
        print(rating)
        if browse_id == None:
            abort(400, message="Browse Id needed")
        if rating == None:
            playlist = ytmusic.get_playlist(browse_id)
            response = make_response(playlist, 200)
        elif rating == "LIKE" or rating == "DISLIKE" or rating == "INDIFFERENT":
            response = ytmusic.rate_playlist(browse_id, rating)
        else:
            abort(400, message="Rating value invalid")
        return response

class Home(Resource):
    def get(self):
        home = ytmusic.get_home(limit=5)
        response = make_response(home, 200)
        return response

class Artist(Resource):
    def post(self, type=None):
        browse_id = artist_post_args.parse_args()["browseId"]
        channel_id = artist_post_args.parse_args()["channelId"]
        if browse_id == None:
            abort(400, message="Browse Id needed")
        if type == "albums" or type == "singles":
            result = ytmusic.get_artist_albums(channelId=channel_id, params=browse_id)
        else:
            result = ytmusic.get_artist(browse_id)
        response = make_response(result, 200)
        return response

class Library(Resource):
    def get(self, type):
        if type == "liked":
           result = ytmusic.get_liked_songs()
        elif type == "playlists":
            result = ytmusic.get_library_playlists()
        elif type == "albums":
            result = ytmusic.get_library_albums(order="recently_added")
        elif type == "songs":
            result = ytmusic.get_library_songs(order="recently_added")
        elif type == "artists":
            result = ytmusic.get_library_artists(order="recently_added")
        elif type == "subscriptions":
            result = ytmusic.get_library_subscriptions(order="recently_added")

        response = make_response(result, 200)
        return response


api.add_resource(Search, "/api/search/")
api.add_resource(Media, "/api/media/")
api.add_resource(Album, "/api/album/")
api.add_resource(Playlist, "/api/playlist/")
api.add_resource(Home, "/api/home/")
api.add_resource(Artist, "/api/artist/", "/api/artist/<string:type>")
api.add_resource(Library, "/api/library/<string:type>")


if __name__ == "__main__":
    app.run(port=8000, debug=True)