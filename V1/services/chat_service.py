from django.core.exceptions import PermissionDenied
from django.utils import timezone
from communications.models import Room, Message, MessageReadStatus
from rest_framework import serializers
from django.contrib.auth.models import User
from django.db.models import Max


class RoomSerializer(serializers.ModelSerializer):
    chat_name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()  # 👈 Add this line

    class Meta:
        model = Room
        fields = ['id', 'name', 'chat_name', 'created_at', 'last_message', 'unread_count']  # 👈 Include unread_count

    def get_chat_name(self, room):
        user = self.context.get('request').user
        return room.get_chat_name(user)

    def get_last_message(self, room):
        last_msg = room.messages.order_by("-timestamp").first()
        if last_msg:
            return {
                "content": last_msg.content,
                "timestamp": last_msg.timestamp
            }
        return None

    def get_unread_count(self, room):  # 👈 Add this method
        user = self.context.get('request').user
        return MessageReadStatus.objects.filter(
            user=user,
            message__room=room,
            read=False
        ).exclude(message__user=user).count()


class MessageSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'user_id', 'username', 'content', 'timestamp']

class ChatService:
    def get_user_rooms(self, user):
        """Return all rooms where the user is a participant."""
        return (
            Room.objects
            .filter(participants=user)
            .annotate(latest_message=Max('messages__timestamp'))
            .order_by('-latest_message')  # Most recent first
        )

    def get_room_messages(self, room, user):
        """Retrieve messages for a room if the user is a participant."""
        if user not in room.participants.all():
            raise PermissionDenied("You are not a participant of this room.")
        return room.messages.all().order_by("timestamp")

    def send_message(self, room, user, content):
        """Create a new message in a room and create read statuses for the other participants."""
        message = Message.objects.create(user=user, room=room, content=content)
        # Create a read status record for every other participant
        for participant in room.participants.exclude(id=user.id):
            MessageReadStatus.objects.create(message=message, user=participant)
        return message

    def mark_message_as_read(self, message, user):
        """Mark a message as read for the given user."""
        status, created = MessageReadStatus.objects.get_or_create(message=message, user=user)
        if not status.read:
            status.read = True
            status.read_at = timezone.now()
            status.save()
        return status

    def initiate_chat(self, user, other_user):
        """
        Get or create a chat room between the current user and the other user.
        If a room already exists with these two participants, it is returned;
        otherwise, a new room is created.
        """
        room = Room.objects.filter(participants=user).filter(participants=other_user).first()
        if not room:
            # Generate a room name from the two usernames (sorted for consistency)
            participants = sorted([user.username, other_user.username])
            room_name = f"{participants[0]}_{participants[1]}"
            room = Room.objects.create(name=room_name)
            room.participants.add(user, other_user)
        return room

# Instantiate a single service instance to be used in API views.
chat_service = ChatService()
