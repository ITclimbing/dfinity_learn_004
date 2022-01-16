import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import List "mo:base/List";
import Iter "mo:base/Iter";

actor class (owner  : Principal){
    public type Message = {
        msg : Text;
        time : Time.Time;
    };
    public type Microblog = actor {
        follow : shared(Principal) -> async();
        follows: shared query () ->async [Principal];
        post: shared (Text) ->async();
        posts : shared query (Time.Time) ->async [Message];
        timeline : shared (Time.Time) ->async [Message];
    };

    private stable var followed  = List.nil<Principal>();
    private stable var messages = List.nil<Message>();
    private stable var _owner = owner;

    public shared func follow( id : Principal) : async(){
        followed := List.push(id , followed);
    };
    public shared query func  follows(): async ([Principal]){
        List.toArray(followed)
    };
    public shared(msg) func post( text : Text) : async(){
        assert(msg.caller == _owner);
        messages := List.push({
            msg = text;
            time = Time.now();
        } , messages);
    };
    public shared query func posts(since : Time.Time) : async([Message]){
        List.toArray(List.filter(messages, func (x : Message) : Bool { x.time > since }))
    };
    public shared func timeline(since : Time.Time) : async ([Message]){
        var all  = List.nil<Message>();
        for( id in Iter.fromList(followed)){
            let cidActor : Microblog = actor(Principal.toText(id));
            let msgs = await cidActor.posts(since);
            for( msg in Iter.fromArray(msgs)){
                all := List.push(msg ,all)
            };
        };
        List.toArray(all)
    };
};
